<?php

namespace App\Http\Controllers;

use App\Models\Attendance;
use Carbon\Carbon;
use Illuminate\Http\Request;

class AttendanceController extends Controller
{
    /**
     * Monitoring absensi harian
     */
    public function index(Request $request)
    {
        $date = $request->input('date', today()->format('Y-m-d'));
        $search = $request->input('search');
        $dayStart = Carbon::parse($date)->startOfDay();
        $dayEnd = $dayStart->copy()->endOfDay();

        // Ambil semua absensi di tanggal tersebut
        $query = Attendance::with('employee:id,name,jabatan')
            ->whereBetween('timestamp', [$dayStart, $dayEnd])
            ->orderBy('timestamp', 'asc');

        if ($search) {
            $query->where('name', 'like', "%{$search}%");
        }

        $rawData = $query->get();

        // Group per karyawan: ambil masuk & pulang
        $grouped = [];
        foreach ($rawData as $row) {
            $key = $row->employee_id ?? $row->phone;

            if (!isset($grouped[$key])) {
                $grouped[$key] = [
                    'id'             => $row->id,
                    'employee_id'    => $row->employee_id,
                    'name'           => $row->name,
                    'jabatan'        => $row->employee->jabatan ?? '-',
                    'masuk'          => null,
                    'masuk_id'       => null,
                    'status_masuk'   => null,
                    'pulang'         => null,
                    'pulang_id'      => null,
                    'status_pulang'  => null,
                    'is_lembur'      => false,
                    'lembur_fee'     => 0,
                    'location'       => $row->location_name,
                ];
            }

            if ($row->type === 'Masuk') {
                $grouped[$key]['masuk']        = Carbon::parse($row->timestamp)->format('H:i');
                $grouped[$key]['masuk_id']     = $row->id;
                $grouped[$key]['status_masuk'] = $row->status;
                $grouped[$key]['location']     = $row->location_name;
            } elseif ($row->type === 'Pulang') {
                $grouped[$key]['pulang']        = Carbon::parse($row->timestamp)->format('H:i');
                $grouped[$key]['pulang_id']     = $row->id;
                $grouped[$key]['status_pulang'] = $row->status;
                $grouped[$key]['is_lembur']     = $row->is_lembur;
                $grouped[$key]['lembur_fee']    = $row->lembur_fee;
            }
        }

        // Daftar tanggal yang ada data (untuk date picker)
        $availableDates = Attendance::selectRaw('DATE(timestamp) as tgl')
            ->groupBy('tgl')
            ->orderBy('tgl', 'desc')
            ->limit(30)
            ->pluck('tgl');

        return view('admin.attendance.index', [
            'grouped'        => $grouped,
            'date'           => $date,
            'search'         => $search,
            'availableDates' => $availableDates,
        ]);
    }

    /**
     * Update status absensi (edit status / tandai lembur)
     */
    public function update(Request $request, int $id)
    {
        $request->validate([
            'status'     => 'nullable|string|in:tepat_waktu,telat,normal,pulang_awal,lembur',
            'is_lembur'  => 'nullable|boolean',
        ]);

        $attendance = Attendance::findOrFail($id);

        if ($request->has('status')) {
            $attendance->status = $request->status;
        }

        if ($request->has('is_lembur')) {
            $attendance->is_lembur = $request->is_lembur;
            $attendance->lembur_fee = $request->is_lembur
                ? config('attendance.biaya_lembur', 30000)
                : 0;
        }

        $attendance->save();

        return redirect()->back()->with('success', 'Status absensi berhasil diupdate.');
    }
}
