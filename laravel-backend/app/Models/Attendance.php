<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Attendance extends Model
{
    protected $fillable = [
        'employee_id',
        'name',
        'phone',
        'type',
        'timestamp',
        'latitude',
        'longitude',
        'location_name',
        'status',
        'is_lembur',
        'lembur_fee',
    ];

    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }
}
