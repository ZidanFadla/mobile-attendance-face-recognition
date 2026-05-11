<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class Employee extends Authenticatable
{
    use HasApiTokens;

    protected $fillable = [
        'name',
        'phone',
        'jabatan',
        'tanggal_masuk',
        'face_embedding',
        'profile_photo_path',
        'kasbon_limit',
        'annual_leave_quota',
        'username',
        'password',
    ];

    protected $hidden = [
        'password',
        'face_embedding',
    ];

    public function attendances(): HasMany
    {
        return $this->hasMany(Attendance::class);
    }

    public function leaveRequests(): HasMany
    {
        return $this->hasMany(LeaveRequest::class);
    }

    public function cashAdvanceRequests(): HasMany
    {
        return $this->hasMany(CashAdvanceRequest::class);
    }
}
