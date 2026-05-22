<?php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Attendance;
use Carbon\Carbon;

class AttendanceApiController extends Controller
{
    public function index(Request $request)
    {
        $employee = $request->user();

        $attendances = Attendance::where('employee_id', $employee->id)
            ->orderBy('timestamp', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $attendances,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'type' => ['required', 'string', 'in:Masuk,Pulang'],
            'timestamp' => ['required', 'date'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'location_name' => ['nullable', 'string', 'max:255'],
        ]);

        $employee = $request->user();
        $timestamp = Carbon::parse($request->timestamp);
        $type = $validated['type'];
        $status = null;
        $isLembur = false;
        $lemburFee = 0;

        $alreadyExists = Attendance::where('employee_id', $employee->id)
            ->where('type', $type)
            ->whereDate('timestamp', $timestamp->toDateString())
            ->exists();

        if ($alreadyExists) {
            return response()->json([
                'success' => false,
                'message' => "Absen {$type} untuk hari ini sudah tercatat",
            ], 409);
        }

        if ($type === 'Masuk') {
            $batasTepatWaktu = Carbon::parse($timestamp->format('Y-m-d') . ' ' . config('attendance.jam_masuk'))
                ->addMinutes(config('attendance.toleransi_menit'));

            $status = $timestamp->lte($batasTepatWaktu) ? 'tepat_waktu' : 'telat';

        } elseif ($type === 'Pulang') {
            $batasPulang = Carbon::parse($timestamp->format('Y-m-d') . ' ' . config('attendance.jam_pulang'));

            if ($timestamp->lt($batasPulang)) {
                $status = 'pulang_awal';
            } elseif ($timestamp->eq($batasPulang)) {
                $status = 'normal';
            } else {
                $status = 'lembur';
                $isLembur = true;
                $lemburFee = config('attendance.biaya_lembur');
            }
        }

        $attendance = Attendance::create([
            'employee_id' => $employee->id,
            'name' => $employee->name,
            'phone' => $employee->phone,
            'type' => $type,
            'timestamp' => $timestamp,
            'latitude' => $validated['latitude'] ?? null,
            'longitude' => $validated['longitude'] ?? null,
            'location_name' => $validated['location_name'] ?? null,
            'status' => $status,
            'is_lembur' => $isLembur,
            'lembur_fee' => $lemburFee,
        ]);

        return response()->json([
            'success' => true,
            'data' => $attendance,
            'status' => $status,
            'lembur' => $isLembur,
        ], 201);
    }
}
