<?php

namespace App\Http\Controllers;

use App\Models\Attendance;
use App\Models\Employee;
use Carbon\Carbon;

class DashboardController extends Controller
{
    public function index()
    {
        $todayStart = Carbon::today()->startOfDay();
        $todayEnd = $todayStart->copy()->endOfDay();

        $totalKaryawan = Employee::count();

        $todayStats = Attendance::query()
            ->whereBetween('timestamp', [$todayStart, $todayEnd])
            ->selectRaw(
                'COUNT(DISTINCT CASE WHEN type = ? THEN employee_id END) as hadir_hari_ini,
                SUM(CASE WHEN type = ? AND status = ? THEN 1 ELSE 0 END) as terlambat_hari_ini,
                SUM(CASE WHEN is_lembur = true THEN 1 ELSE 0 END) as lembur_hari_ini',
                ['Masuk', 'Masuk', 'telat']
            )
            ->first();

        $recentAttendance = Attendance::with('employee:id,name,jabatan')
            ->orderBy('timestamp', 'desc')
            ->limit(10)
            ->get();

        return view('admin.dashboard', [
            'totalKaryawan' => $totalKaryawan,
            'hadirHariIni' => (int) ($todayStats->hadir_hari_ini ?? 0),
            'terlatHariIni' => (int) ($todayStats->terlambat_hari_ini ?? 0),
            'lemburHariIni' => (int) ($todayStats->lembur_hari_ini ?? 0),
            'recentAttendance' => $recentAttendance,
        ]);
    }
}
