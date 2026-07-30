<?php

namespace Tests\Feature;

use App\Models\Employee;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class EmployeeAdminPasswordTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_reset_employee_password_for_mobile_login(): void
    {
        $admin = User::factory()->create();
        $employee = Employee::create([
            'name' => 'Budi Santoso',
            'phone' => '081234567890',
            'jabatan' => 'OB',
            'username' => 'budi',
            'password' => Hash::make('password-lama'),
        ]);
        $oldToken = $employee->createToken('mobile')->plainTextToken;

        $this->actingAs($admin)->put(route('admin.employees.update', $employee), [
            'name' => 'Budi Santoso',
            'phone' => '081234567890',
            'jabatan' => 'OB',
            'username' => ' BUDI ',
            'password' => ' password-baru ',
        ])->assertRedirect(route('admin.employees.show', $employee));

        $employee->refresh();

        $this->assertSame('budi', $employee->username);
        $this->assertTrue(Hash::check('password-baru', $employee->password));
        $this->assertDatabaseMissing('personal_access_tokens', [
            'tokenable_type' => Employee::class,
            'tokenable_id' => $employee->id,
        ]);

        $this->postJson('/api/auth/login', [
            'username' => 'BUDI',
            'password' => 'password-lama',
        ])->assertUnauthorized();

        $this->postJson('/api/auth/login', [
            'username' => 'BUDI',
            'password' => 'password-baru',
        ])
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('employee.username', 'budi');
    }
}