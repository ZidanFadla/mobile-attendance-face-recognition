<?php

namespace App\Http\Controllers;

use App\Models\Employee;
use App\Models\Attendance;
use Carbon\Carbon;

class DashboardController extends Controller
{
    public function index()
    {
        $today = Carbon::today();

        // Statistik sederhana
        $totalKaryawan = Employee::count();

        $hadirHariIni = Attendance::whereDate('timestamp', $today)
            ->where('type', 'Masuk')
            ->distinct('employee_id')
            ->count('employee_id');

        $terlatHariIni = Attendance::whereDate('timestamp', $today)
            ->where('type', 'Masuk')
            ->where('status', 'telat')
            ->count();

        $lemburHariIni = Attendance::whereDate('timestamp', $today)
            ->where('is_lembur', true)
            ->count();

        // 10 absensi terbaru
        $recentAttendance = Attendance::with('employee:id,name,jabatan')
            ->orderBy('timestamp', 'desc')
            ->limit(10)
            ->get();

        return view('admin.dashboard', [
            'totalKaryawan' => $totalKaryawan,
            'hadirHariIni' => $hadirHariIni,
            'terlatHariIni' => $terlatHariIni,
            'lemburHariIni' => $lemburHariIni,
            'recentAttendance' => $recentAttendance,
        ]);
    }
}
