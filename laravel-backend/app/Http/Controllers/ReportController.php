<?php

namespace App\Http\Controllers;

use App\Models\Attendance;
use App\Models\Employee;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    public function index(Request $request)
    {
        $reportType = $request->get('report_type');
        $tab = $reportType ? match ($reportType) {
            'daily' => 'harian',
            'monthly' => 'bulanan',
            'yearly' => 'tahunan',
            default => $request->get('tab', 'harian'),
        } : $request->get('tab', 'harian');

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
            'employeesFilter' => Employee::orderBy('name')->get(['id', 'name', 'jabatan']),
        ]));
    }

    private function rekapHarian(Request $request): array
    {
        $date = $request->get('date', today()->format('Y-m-d'));
        $dayStart = Carbon::parse($date)->startOfDay();
        $dayEnd = $dayStart->copy()->endOfDay();
        $employeeId = $request->integer('employee_id') ?: null;
        $status = $request->get('status');

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
        $month = $request->get('month', now()->format('Y-m'));
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
        $year = (int) $request->get('year', now()->year);

        $monthlyData = [];
        for ($m = 1; $m <= 12; $m++) {
            $start = Carbon::create($year, $m, 1)->startOfMonth();
            $end = $start->copy()->endOfMonth();

            $monthlyData[] = [
                'bulan' => $start->translatedFormat('F'),
                'hadir' => Attendance::where('type', 'Masuk')->whereBetween('timestamp', [$start, $end])->distinct('employee_id')->count('employee_id'),
                'telat' => Attendance::where('type', 'Masuk')->where('status', 'telat')->whereBetween('timestamp', [$start, $end])->count(),
                'lembur' => Attendance::where('is_lembur', true)->whereBetween('timestamp', [$start, $end])->count(),
            ];
        }

        return [
            'year' => $year,
            'monthlyData' => $monthlyData,
        ];
    }

    private function rekapLembur(Request $request): array
    {
        $month = $request->get('month', now()->format('Y-m'));
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
