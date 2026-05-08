<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    protected $fillable = [
        'sender_id',
        'employee_id',
        'type',
        'content',
        'file_path',
        'file_name',
        'image_path',
        'image_name',
        'is_read',
    ];

    protected $casts = [
        'is_read' => 'boolean',
    ];

    public function sender()
    {
        return $this->belongsTo(User::class, 'sender_id');
    }

    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }
}
