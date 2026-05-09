<?php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Employee;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class EmployeeAuthController extends Controller
{
    // Register karyawan baru
    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string',
            'phone' => 'required|string',
            'username' => 'required|string|unique:employees,username',
            'password' => 'required|string|min:6',
        ]);

        // Cek apakah nomor HP sudah terdaftar
        $existing = Employee::where('phone', $request->phone)->first();
        if ($existing) {
            return response()->json([
                'success' => false,
                'message' => 'Nomor HP sudah terdaftar'
            ], 400);
        }

        $employee = Employee::create([
            'name' => $request->name,
            'phone' => $request->phone,
            'username' => $request->username,
            'password' => Hash::make($request->password),
        ]);
        $token = $employee->createToken('mobile')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Akun berhasil dibuat! Silakan registrasi wajah.',
            'token' => $token,
            'employee' => $this->employeePayload($employee),
        ], 201);
    }

    // Login karyawan
    public function login(Request $request)
    {
        $request->validate([
            'username' => 'required|string',
            'password' => 'required|string',
        ]);

        $employee = Employee::where('username', $request->username)->first();

        if (!$employee || !Hash::check($request->password, $employee->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Username atau password salah'
            ], 401);
        }
        $employee->tokens()->where('name', 'mobile')->delete();
        $token = $employee->createToken('mobile')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login berhasil',
            'token' => $token,
            'employee' => $this->employeePayload($employee),
        ]);
    }

    public function updateProfile(Request $request)
    {
        $employee = $request->user();

        $request->validate([
            'name' => 'required|string|max:255',
            'phone' => [
                'required',
                'string',
                'max:20',
                Rule::unique('employees', 'phone')->ignore($employee->id),
            ],
        ]);

        $employee->update([
            'name' => $request->name,
            'phone' => $request->phone,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Profile berhasil diperbarui.',
            'employee' => $this->employeePayload($employee),
        ]);
    }

    public function uploadProfilePhoto(Request $request)
    {
        $employee = $request->user();

        $request->validate([
            'profile_photo' => 'required|image|mimes:jpg,jpeg,png,webp|max:2048',
        ]);

        if ($employee->profile_photo_path) {
            Storage::disk('public')->delete($employee->profile_photo_path);
        }

        $path = $request->file('profile_photo')->store('profile-photos', 'public');
        $employee->update(['profile_photo_path' => $path]);

        return response()->json([
            'success' => true,
            'message' => 'Foto profile berhasil diperbarui.',
            'employee' => $this->employeePayload($employee),
        ]);
    }

    public function changePassword(Request $request)
    {
        $employee = $request->user();

        $request->validate([
            'current_password' => 'required|string',
            'password' => 'required|string|min:6|confirmed',
        ]);

        if (!Hash::check($request->current_password, $employee->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Password saat ini tidak sesuai.',
            ], 422);
        }

        $employee->update([
            'password' => Hash::make($request->password),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Password berhasil diganti.',
        ]);
    }

    private function employeePayload(Employee $employee): array
    {
        return [
            'id' => $employee->id,
            'name' => $employee->name,
            'phone' => $employee->phone,
            'username' => $employee->username,
            'profile_photo_url' => $employee->profile_photo_path
                ? asset('storage/' . $employee->profile_photo_path)
                : null,
        ];
    }
}
