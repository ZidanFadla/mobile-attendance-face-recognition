<?php

namespace App\Http\Controllers;

use App\Models\Attendance;
use App\Models\Employee;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    public function index(Request $request)
    {
        $reportType = $request->input('report_type');
        $tab = $reportType ? match ($reportType) {
            'daily' => 'harian',
            'monthly' => 'bulanan',
            'yearly' => 'tahunan',
            default => $request->input('tab', 'harian'),
        } : $request->input('tab', 'harian');

        $data = match ($tab) {
            'bulanan' => $this->rekapBulanan($request),
            'tahunan' => $this->rekapTahunan($request),
            'lembur' => $this->rekapLembur($request),
            default => $this->rekapHarian($request),
        };

        return view('admin.reports.index', array_merge($data, [
            'tab' => $tab,
            'reportType' => match ($tab) {
                'bulanan' => 'monthly',
                'tahunan' => 'yearly',
                default => 'daily',
            },
            'employeesFilter' => Cache::store('file')->remember('admin_report_employee_filter_options', 60, fn () =>
                Employee::orderBy('name')->get(['id', 'name', 'jabatan'])
            ),
        ]));
    }

    private function rekapHarian(Request $request): array
    {
        $date = $request->input('date', today()->format('Y-m-d'));
        $dayStart = Carbon::parse($date)->startOfDay();
        $dayEnd = $dayStart->copy()->endOfDay();
        $employeeId = $request->integer('employee_id') ?: null;
        $status = $request->input('status');

        $attendances = Attendance::with('employee:id,name,jabatan')
            ->whereBetween('timestamp', [$dayStart, $dayEnd])
            ->when($employeeId, fn ($q) => $q->where('employee_id', $employeeId))
            ->when($status && $status !== 'all', fn ($q) => $q->where('status', $status))
            ->orderBy('timestamp')
            ->get();

        return [
            'date' => $date,
            'attendances' => $attendances,
            'totalMasuk' => $attendances->where('type', 'Masuk')->unique('employee_id')->count(),
            'totalTerlat' => $attendances->where('type', 'Masuk')->where('status', 'telat')->count(),
            'totalLembur' => $attendances->where('is_lembur', true)->count(),
        ];
    }

    private function rekapBulanan(Request $request): array
    {
        $month = $request->input('month', now()->format('Y-m'));
        $start = Carbon::parse($month)->startOfMonth();
        $end = Carbon::parse($month)->endOfMonth();
        $employeeId = $request->integer('employee_id') ?: null;

        $employees = Employee::query()
            ->when($employeeId, fn ($q) => $q->where('id', $employeeId))
            ->withCount([
                'attendances as hadir_count' => fn ($q) => $q->where('type', 'Masuk')->whereBetween('timestamp', [$start, $end]),
                'attendances as telat_count' => fn ($q) => $q->where('type', 'Masuk')->where('status', 'telat')->whereBetween('timestamp', [$start, $end]),
                'attendances as lembur_count' => fn ($q) => $q->where('is_lembur', true)->whereBetween('timestamp', [$start, $end]),
            ])
            ->orderBy('name')
            ->get();

        return [
            'month' => $month,
            'employees' => $employees,
            'totalHadir' => $employees->sum('hadir_count'),
            'totalTerlat' => $employees->sum('telat_count'),
            'totalLembur' => $employees->sum('lembur_count'),
        ];
    }

    private function rekapTahunan(Request $request): array
    {
        $year = (int) $request->input('year', now()->year);
        $start = Carbon::create($year, 1, 1)->startOfYear();
        $end = $start->copy()->endOfYear();

        $statsByMonth = Attendance::query()
            ->whereBetween('timestamp', [$start, $end])
            ->selectRaw(
                'EXTRACT(MONTH FROM "timestamp")::int as month_number,
                COUNT(DISTINCT CASE WHEN type = ? THEN employee_id END) as hadir,
                SUM(CASE WHEN type = ? AND status = ? THEN 1 ELSE 0 END) as telat,
                SUM(CASE WHEN is_lembur = true THEN 1 ELSE 0 END) as lembur',
                ['Masuk', 'Masuk', 'telat']
            )
            ->groupBy(DB::raw('EXTRACT(MONTH FROM "timestamp")'))
            ->get()
            ->keyBy('month_number');

        $monthlyData = collect(range(1, 12))->map(function ($month) use ($year, $statsByMonth) {
            $monthStart = Carbon::create($year, $month, 1)->startOfMonth();
            $stats = $statsByMonth->get($month);

            return [
                'bulan' => $monthStart->translatedFormat('F'),
                'hadir' => (int) ($stats->hadir ?? 0),
                'telat' => (int) ($stats->telat ?? 0),
                'lembur' => (int) ($stats->lembur ?? 0),
            ];
        })->all();

        return [
            'year' => $year,
            'monthlyData' => $monthlyData,
        ];
    }

    private function rekapLembur(Request $request): array
    {
        $month = $request->input('month', now()->format('Y-m'));
        $start = Carbon::parse($month)->startOfMonth();
        $end = Carbon::parse($month)->endOfMonth();

        $lemburData = DB::table('attendances')
            ->join('employees', 'attendances.employee_id', '=', 'employees.id')
            ->select('employees.id', 'employees.name', 'employees.jabatan', DB::raw('COUNT(*) as total_hari_lembur'), DB::raw('SUM(lembur_fee) as total_fee'))
            ->where('attendances.is_lembur', true)
            ->whereBetween('attendances.timestamp', [$start, $end])
            ->groupBy('employees.id', 'employees.name', 'employees.jabatan')
            ->orderByDesc('total_hari_lembur')
            ->get();

        return [
            'month' => $month,
            'lemburData' => $lemburData,
        ];
    }
}
