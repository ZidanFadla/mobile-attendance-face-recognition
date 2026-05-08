<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\EmployeeController;
use App\Http\Controllers\AttendanceController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\MessageController;

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
// Admin Panel — 4 halaman utama
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

    // 5. Pesan ke Karyawan
    Route::get('/messages', [MessageController::class, 'index'])->name('messages.index');
    Route::post('/messages', [MessageController::class, 'store'])->name('messages.store');
    Route::delete('/messages/{message}', [MessageController::class, 'destroy'])->name('messages.destroy');
});