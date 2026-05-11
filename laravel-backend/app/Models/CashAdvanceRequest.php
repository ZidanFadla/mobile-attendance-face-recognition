<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CashAdvanceRequest extends Model
{
    public const STATUS_PENDING = 'pending';
    public const STATUS_APPROVED = 'approved';
    public const STATUS_REJECTED = 'rejected';
    public const STATUS_DISBURSED = 'disbursed';
    public const STATUS_INSTALLMENT = 'installment';
    public const STATUS_PAID = 'paid';
    public const REVIEW_STATUSES = [
        self::STATUS_APPROVED,
        self::STATUS_REJECTED,
    ];
    public const ACTIVE_STATUSES = [
        self::STATUS_APPROVED,
        self::STATUS_DISBURSED,
        self::STATUS_INSTALLMENT,
    ];
    public const ADMIN_STATUSES = [
        self::STATUS_PENDING,
        self::STATUS_APPROVED,
        self::STATUS_DISBURSED,
        self::STATUS_INSTALLMENT,
        self::STATUS_PAID,
        self::STATUS_REJECTED,
    ];

    protected $fillable = [
        'employee_id',
        'amount',
        'outstanding_amount',
        'purpose',
        'needed_date',
        'repayment_method',
        'installment_count',
        'installment_paid',
        'reason',
        'disbursement_method',
        'account_number',
        'attachment_path',
        'attachment_name',
        'status',
        'reviewed_by',
        'reviewed_at',
        'disbursed_at',
        'paid_at',
        'admin_note',
    ];

    protected $appends = [
        'attachment_url',
    ];

    protected $casts = [
        'amount' => 'integer',
        'outstanding_amount' => 'integer',
        'installment_count' => 'integer',
        'installment_paid' => 'integer',
        'needed_date' => 'date',
        'reviewed_at' => 'datetime',
        'disbursed_at' => 'datetime',
        'paid_at' => 'datetime',
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
