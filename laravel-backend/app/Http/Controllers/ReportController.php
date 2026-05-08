<?php

namespace App\Http\Controllers;

use App\Models\Attendance;
use App\Models\Employee;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    public function index(Request $request)
    {
        $tab = $request->get('tab', 'harian');

        $data = match ($tab) {
            'bulanan'  => $this->rekapBulanan($request),
            'tahunan'  => $this->rekapTahunan($request),
            'lembur'   => $this->rekapLembur($request),
            default    => $this->rekapHarian($request),
        };

        return view('admin.reports.index', array_merge($data, ['tab' => $tab]));
    }

    /**
     * Rekap Harian — per tanggal
     */
    private function rekapHarian(Request $request): array
    {
        $date = $request->get('date', today()->format('Y-m-d'));

        $attendances = Attendance::with('employee:id,name,jabatan')
            ->whereDate('timestamp', $date)
            ->orderBy('timestamp')
            ->get();

        $totalMasuk = $attendances->where('type', 'Masuk')->unique('employee_id')->count();
        $totalTerlat = $attendances->where('type', 'Masuk')->where('status', 'telat')->count();
        $totalLembur = $attendances->where('is_lembur', true)->count();

        return [
            'date'        => $date,
            'attendances' => $attendances,
            'totalMasuk'  => $totalMasuk,
            'totalTerlat' => $totalTerlat,
            'totalLembur' => $totalLembur,
        ];
    }

    /**
     * Rekap Bulanan — per bulan
     */
    private function rekapBulanan(Request $request): array
    {
        $month = $request->get('month', now()->format('Y-m'));
        $start = Carbon::parse($month)->startOfMonth();
        $end   = Carbon::parse($month)->endOfMonth();

        $employees = Employee::withCount([
            'attendances as hadir_count' => function ($q) use ($start, $end) {
                $q->where('type', 'Masuk')->whereBetween('timestamp', [$start, $end]);
            },
            'attendances as telat_count' => function ($q) use ($start, $end) {
                $q->where('type', 'Masuk')->where('status', 'telat')
                  ->whereBetween('timestamp', [$start, $end]);
            },
            'attendances as lembur_count' => function ($q) use ($start, $end) {
                $q->where('is_lembur', true)->whereBetween('timestamp', [$start, $end]);
            },
        ])->orderBy('name')->get();

        $totalHadir  = $employees->sum('hadir_count');
        $totalTerlat = $employees->sum('telat_count');
        $totalLembur = $employees->sum('lembur_count');

        return [
            'month'       => $month,
            'employees'   => $employees,
            'totalHadir'  => $totalHadir,
            'totalTerlat' => $totalTerlat,
            'totalLembur' => $totalLembur,
        ];
    }

    /**
     * Rekap Tahunan — per tahun
     */
    private function rekapTahunan(Request $request): array
    {
        $year = $request->get('year', now()->year);

        // Rekap per bulan dalam setahun
        $monthlyData = [];
        for ($m = 1; $m <= 12; $m++) {
            $start = Carbon::create($year, $m, 1)->startOfMonth();
            $end   = $start->copy()->endOfMonth();

            $hadir  = Attendance::where('type', 'Masuk')
                ->whereBetween('timestamp', [$start, $end])
                ->distinct('employee_id')->count('employee_id');

            $telat  = Attendance::where('type', 'Masuk')->where('status', 'telat')
                ->whereBetween('timestamp', [$start, $end])->count();

            $lembur = Attendance::where('is_lembur', true)
                ->whereBetween('timestamp', [$start, $end])->count();

            $monthlyData[] = [
                'bulan'   => $start->translatedFormat('F'),
                'hadir'   => $hadir,
                'telat'   => $telat,
                'lembur'  => $lembur,
            ];
        }

        return [
            'year'        => $year,
            'monthlyData' => $monthlyData,
        ];
    }

    /**
     * Rekap Lembur — detail per karyawan
     */
    private function rekapLembur(Request $request): array
    {
        $month = $request->get('month', now()->format('Y-m'));
        $start = Carbon::parse($month)->startOfMonth();
        $end   = Carbon::parse($month)->endOfMonth();

        $lemburData = DB::table('attendances')
            ->join('employees', 'attendances.employee_id', '=', 'employees.id')
            ->select(
                'employees.id',
                'employees.name',
                'employees.jabatan',
                DB::raw('COUNT(*) as total_hari_lembur'),
                DB::raw('SUM(lembur_fee) as total_fee')
            )
            ->where('attendances.is_lembur', true)
            ->whereBetween('attendances.timestamp', [$start, $end])
            ->groupBy('employees.id', 'employees.name', 'employees.jabatan')
            ->orderBy('total_hari_lembur', 'desc')
            ->get();

        return [
            'month'      => $month,
            'lemburData' => $lemburData,
        ];
    }
}
