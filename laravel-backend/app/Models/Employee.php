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
}
