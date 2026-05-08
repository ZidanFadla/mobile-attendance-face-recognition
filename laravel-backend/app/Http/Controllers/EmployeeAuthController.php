<?php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Employee;
use Illuminate\Support\Facades\Hash;

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
            'employee' => [
                'id' => $employee->id,
                'name' => $employee->name,
                'phone' => $employee->phone,
                'username' => $employee->username,
            ]
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
            'employee' => [
                'id' => $employee->id,
                'name' => $employee->name,
                'phone' => $employee->phone,
                'username' => $employee->username,
            ]
        ]);
    }
}
