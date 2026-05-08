<?php

namespace App\Http\Controllers;

use App\Models\Employee;
use App\Models\Attendance;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Carbon\Carbon;

class EmployeeController extends Controller
{
    /**
     * Daftar semua karyawan
     */
    public function index(Request $request)
    {
        $query = Employee::query();

        // Search sederhana
        if ($search = $request->get('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%")
                  ->orWhere('jabatan', 'like', "%{$search}%");
            });
        }

        $employees = $query->orderBy('name')->paginate(15)->withQueryString();

        return view('admin.employees.index', compact('employees'));
    }

    /**
     * Form tambah karyawan
     */
    public function create()
    {
        return view('admin.employees.create');
    }

    /**
     * Simpan karyawan baru
     */
    public function store(Request $request)
    {
        $request->validate([
            'name'     => 'required|string|max:255',
            'phone'    => 'required|string|max:20|unique:employees,phone',
            'jabatan'  => 'required|string|in:OB,Security,Cleaning Service,Maintenance',
            'username' => 'required|string|max:255|unique:employees,username',
            'password' => 'required|string|min:6',
        ]);

        Employee::create([
            'name'     => $request->name,
            'phone'    => $request->phone,
            'jabatan'  => $request->jabatan,
            'username' => strtolower($request->username),
            'password' => Hash::make($request->password),
            'tanggal_masuk' => now()->toDateString(),
        ]);

        return redirect()->route('admin.employees.index')
            ->with('success', 'Karyawan berhasil ditambahkan.');
    }

    /**
     * Detail karyawan + history absensi
     */
    public function show(Employee $employee, Request $request)
    {
        $month = $request->get('month', now()->format('Y-m'));
        $startDate = Carbon::parse($month)->startOfMonth();
        $endDate = Carbon::parse($month)->endOfMonth();

        $attendances = Attendance::where('employee_id', $employee->id)
            ->whereBetween('timestamp', [$startDate, $endDate])
            ->orderBy('timestamp', 'desc')
            ->get();

        // Hitung ringkasan
        $totalHadir = $attendances->where('type', 'Masuk')->count();
        $totalTerlat = $attendances->where('type', 'Masuk')->where('status', 'telat')->count();
        $totalLembur = $attendances->where('is_lembur', true)->count();

        return view('admin.employees.show', compact(
            'employee', 'attendances', 'month',
            'totalHadir', 'totalTerlat', 'totalLembur'
        ));
    }

    /**
     * Form edit karyawan
     */
    public function edit(Employee $employee)
    {
        return view('admin.employees.edit', compact('employee'));
    }

    /**
     * Update karyawan
     */
    public function update(Request $request, Employee $employee)
    {
        $request->validate([
            'name'     => 'required|string|max:255',
            'phone'    => 'required|string|max:20|unique:employees,phone,' . $employee->id,
            'jabatan'  => 'required|string|in:OB,Security,Cleaning Service,Maintenance',
            'username' => 'required|string|max:255|unique:employees,username,' . $employee->id,
            'password' => 'nullable|string|min:6',
        ]);

        $employee->update([
            'name'     => $request->name,
            'phone'    => $request->phone,
            'jabatan'  => $request->jabatan,
            'username' => strtolower($request->username),
        ]);

        if ($request->filled('password')) {
            $employee->update(['password' => Hash::make($request->password)]);
        }

        return redirect()->route('admin.employees.show', $employee)
            ->with('success', 'Data karyawan berhasil diupdate.');
    }

    /**
     * Hapus karyawan
     */
    public function destroy(Employee $employee)
    {
        $employee->delete();

        return redirect()->route('admin.employees.index')
            ->with('success', 'Karyawan berhasil dihapus.');
    }
}