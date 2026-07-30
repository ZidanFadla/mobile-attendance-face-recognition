<?php

namespace Tests\Feature;

use App\Models\Employee;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AttendanceApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_clock_in_is_on_time_only_between_0600_and_0800(): void
    {
        $cases = [
            '2026-07-31 05:59:00' => 'telat',
            '2026-07-31 06:00:00' => 'tepat_waktu',
            '2026-07-31 08:00:00' => 'tepat_waktu',
            '2026-07-31 08:01:00' => 'telat',
        ];

        foreach ($cases as $timestamp => $expectedStatus) {
            $employee = Employee::create([
                'name' => 'Employee ' . str_replace([' ', ':', '-'], '', $timestamp),
                'phone' => '08' . preg_replace('/\D/', '', $timestamp),
                'username' => 'employee' . preg_replace('/\D/', '', $timestamp),
                'password' => bcrypt('password'),
            ]);

            Sanctum::actingAs($employee);

            $response = $this->postJson('/api/attendance', [
                'type' => 'Masuk',
                'timestamp' => $timestamp,
                'latitude' => -6.2,
                'longitude' => 106.8,
                'location_name' => 'Jakarta',
            ]);

            $response
                ->assertCreated()
                ->assertJsonPath('status', $expectedStatus);
        }
    }
}