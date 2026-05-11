<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LeaveRequest extends Model
{
    public const STATUS_PENDING = 'pending';
    public const STATUS_APPROVED = 'approved';
    public const STATUS_REJECTED = 'rejected';
    public const REVIEW_STATUSES = [
        self::STATUS_APPROVED,
        self::STATUS_REJECTED,
    ];
    public const ADMIN_STATUSES = [
        self::STATUS_PENDING,
        self::STATUS_APPROVED,
        self::STATUS_REJECTED,
    ];

    protected $fillable = [
        'employee_id',
        'leave_type',
        'start_date',
        'end_date',
        'duration_days',
        'is_half_day',
        'reason',
        'contact_during_leave',
        'handover_note',
        'attachment_path',
        'attachment_name',
        'status',
        'reviewed_by',
        'reviewed_at',
        'admin_note',
    ];

    protected $appends = [
        'attachment_url',
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
        'duration_days' => 'integer',
        'is_half_day' => 'boolean',
        'reviewed_at' => 'datetime',
    ];

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    public function getAttachmentUrlAttribute(): ?string
    {
        return $this->attachment_path ? asset('storage/' . $this->attachment_path) : null;
    }
}
