<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\EmployeeController;
use App\Http\Controllers\AttendanceController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\MessageController;
use App\Http\Controllers\Admin\CashAdvanceRequestController;
use App\Http\Controllers\Admin\LeaveRequestController;
use App\Http\Controllers\Admin\ReportExportController;

Route::get('/', function () {
    return redirect()->route('login');
});

// Breeze auth routes
require __DIR__ . '/auth.php';

// Profile routes
Route::middleware('auth')->group(function () {
    Route::get('/profile', [\App\Http\Controllers\ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [\App\Http\Controllers\ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [\App\Http\Controllers\ProfileController::class, 'destroy'])->name('profile.destroy');
});

// Redirect /dashboard ke admin
Route::get('/dashboard', fn() => redirect()->route('admin.dashboard'))
    ->middleware('auth')
    ->name('dashboard');

// =============================================
// Admin Panel â€” 4 halaman utama
// =============================================
Route::middleware('auth')->prefix('admin')->name('admin.')->group(function () {

    // 1. Dashboard
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');

    // 2. Data Karyawan (CRUD + history absensi)
    Route::resource('employees', EmployeeController::class);

    // 3. Data Absensi
    Route::get('/attendance', [AttendanceController::class, 'index'])->name('attendance.index');
    Route::put('/attendance/{id}', [AttendanceController::class, 'update'])->name('attendance.update');

    // 4. Rekap & Laporan
    Route::get('/reports', [ReportController::class, 'index'])->name('reports.index');
    Route::get('/reports/export/excel', [ReportExportController::class, 'exportExcel'])->name('reports.export.excel');
    Route::get('/reports/export/pdf', [ReportExportController::class, 'exportPdf'])->name('reports.export.pdf');

    // 5. Pesan ke Karyawan
    Route::get('/messages', [MessageController::class, 'index'])->name('messages.index');
    Route::post('/messages', [MessageController::class, 'store'])->name('messages.store');
    Route::delete('/messages/{message}', [MessageController::class, 'destroy'])->name('messages.destroy');

    // 6. Persetujuan cuti dan kasbon
    Route::get('/leave-requests', [LeaveRequestController::class, 'index'])->name('leave-requests.index');
    Route::put('/leave-requests/{leaveRequest}', [LeaveRequestController::class, 'update'])->name('leave-requests.update');
    Route::get('/cash-advance-requests', [CashAdvanceRequestController::class, 'index'])->name('cash-advance-requests.index');
    Route::put('/cash-advance-requests/{cashAdvanceRequest}', [CashAdvanceRequestController::class, 'update'])->name('cash-advance-requests.update');
    Route::put('/cash-advance-requests/{cashAdvanceRequest}/progress', [CashAdvanceRequestController::class, 'progress'])->name('cash-advance-requests.progress');
});
