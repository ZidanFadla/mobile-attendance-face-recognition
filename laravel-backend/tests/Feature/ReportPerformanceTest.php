<?php

namespace Tests\Feature;

use App\Models\Attendance;
use App\Models\Employee;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class ReportPerformanceTest extends TestCase
{
    use RefreshDatabase;

    public function test_daily_report_preview_is_paginated(): void
    {
        $admin = User::factory()->create();
        $date = Carbon::parse('2026-07-31 07:00:00');

        for ($i = 1; $i <= 40; $i++) {
            $employee = Employee::create([
                'name' => "Employee {$i}",
                'phone' => '08123' . str_pad((string) $i, 5, '0', STR_PAD_LEFT),
                'jabatan' => 'OB',
                'username' => 'employee' . $i,
                'password' => Hash::make('password'),
            ]);

            Attendance::create([
                'employee_id' => $employee->id,
                'name' => $employee->name,
                'phone' => $employee->phone,
                'type' => 'Masuk',
                'timestamp' => $date->copy()->addMinutes($i),
                'status' => 'tepat_waktu',
            ]);
        }

        $response = $this->actingAs($admin)->get(route('admin.reports.index', [
            'report_type' => 'daily',
            'date' => '2026-07-31',
        ]));

        $response
            ->assertOk()
            ->assertViewHas('attendances', fn ($attendances) =>
                $attendances->total() === 40 && $attendances->perPage() === 25 && $attendances->count() === 25
            );
    }

    public function test_pdf_export_rejects_too_many_rows_before_rendering(): void
    {
        config(['reports.pdf_max_rows' => 10]);

        $admin = User::factory()->create();

        for ($i = 1; $i <= 11; $i++) {
            Employee::create([
                'name' => "Employee {$i}",
                'phone' => '08234' . str_pad((string) $i, 5, '0', STR_PAD_LEFT),
                'jabatan' => 'OB',
                'username' => 'pdfemployee' . $i,
                'password' => Hash::make('password'),
            ]);
        }

        $response = $this->actingAs($admin)->from(route('admin.reports.index'))->get(route('admin.reports.export.pdf', [
            'report_type' => 'monthly',
            'month' => '2026-07',
        ]));

        $response->assertRedirect(route('admin.reports.index'));
        $this->assertTrue(session('errors')->has('report'));
    }
}