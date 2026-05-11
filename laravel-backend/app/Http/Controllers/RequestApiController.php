<?php

namespace App\Http\Controllers;

use App\Models\CashAdvanceRequest;
use App\Models\LeaveRequest;
use Carbon\Carbon;
use Illuminate\Http\Request;

class RequestApiController extends Controller
{
    public function leaveIndex(Request $request)
    {
        $requests = LeaveRequest::where('employee_id', $request->user()->id)
            ->latest()
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $requests,
        ]);
    }

    public function leaveBalance(Request $request)
    {
        return response()->json([
            'success' => true,
            'data' => $this->leaveBalancePayload($request->user()),
        ]);
    }

    public function leaveStore(Request $request)
    {
        $employee = $request->user();
        $validated = $request->validate([
            'leave_type' => ['required', 'string', 'max:100'],
            'start_date' => ['required', 'date'],
            'end_date' => ['required', 'date', 'after_or_equal:start_date'],
            'is_half_day' => ['sometimes', 'boolean'],
            'reason' => ['required', 'string', 'max:2000'],
            'contact_during_leave' => ['nullable', 'string', 'max:100'],
            'handover_note' => ['nullable', 'string', 'max:2000'],
            'attachment' => ['nullable', 'file', 'mimes:jpg,jpeg,png,webp,pdf', 'max:5120'],
        ]);
        unset($validated['attachment']);

        $duration = $this->leaveDuration(
            $validated['start_date'],
            $validated['end_date'],
            (bool) ($validated['is_half_day'] ?? false)
        );
        $balance = $this->leaveBalancePayload($employee);

        if ($duration > $balance['available']) {
            return response()->json([
                'success' => false,
                'message' => 'Sisa cuti tersedia tidak mencukupi. Sisa tersedia: ' . $balance['available'] . ' hari.',
                'data' => $balance,
            ], 422);
        }

        $attachment = $this->storeAttachment($request, 'leave-requests');

        $leave = LeaveRequest::create([
            ...$validated,
            'employee_id' => $employee->id,
            'duration_days' => $duration,
            'status' => LeaveRequest::STATUS_PENDING,
            ...$attachment,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Pengajuan cuti berhasil dikirim.',
            'data' => $leave,
        ], 201);
    }

    public function cashAdvanceIndex(Request $request)
    {
        $requests = CashAdvanceRequest::where('employee_id', $request->user()->id)
            ->latest()
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $requests,
        ]);
    }

    public function cashAdvanceSummary(Request $request)
    {
        return response()->json([
            'success' => true,
            'data' => $this->cashAdvanceSummaryPayload($request->user()),
        ]);
    }

    public function cashAdvanceStore(Request $request)
    {
        $employee = $request->user();
        $summary = $this->cashAdvanceSummaryPayload($employee);
        $remainingLimit = max((int) $summary['remaining_limit'], 0);

        $validated = $request->validate([
            'amount' => [
                'required',
                'integer',
                'min:1',
                'max:' . max((int) $employee->kasbon_limit, 1),
            ],
            'purpose' => ['required', 'string', 'max:100'],
            'needed_date' => ['required', 'date'],
            'repayment_method' => ['required', 'string', 'max:100'],
            'reason' => ['required', 'string', 'max:2000'],
            'disbursement_method' => ['nullable', 'string', 'max:100'],
            'account_number' => ['nullable', 'string', 'max:100'],
            'attachment' => ['nullable', 'file', 'mimes:jpg,jpeg,png,webp,pdf', 'max:5120'],
        ]);
        unset($validated['attachment']);

        if ((int) $validated['amount'] > $remainingLimit) {
            return response()->json([
                'success' => false,
                'message' => 'Sisa limit kasbon tidak mencukupi. Sisa limit: Rp ' . number_format($remainingLimit, 0, ',', '.') . '.',
                'data' => $summary,
            ], 422);
        }

        $attachment = $this->storeAttachment($request, 'cash-advance-requests');
        $installmentCount = $this->installmentCount($validated['repayment_method']);

        $cashAdvance = CashAdvanceRequest::create([
            ...$validated,
            'employee_id' => $employee->id,
            'installment_count' => $installmentCount,
            'status' => CashAdvanceRequest::STATUS_PENDING,
            ...$attachment,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Pengajuan kasbon berhasil dikirim.',
            'data' => $cashAdvance,
        ], 201);
    }

    public function cancel(Request $request, string $type, int $id)
    {
        $model = $this->requestModel($type);
        abort_if($model === null, 404);

        $record = $model::where('employee_id', $request->user()->id)->findOrFail($id);

        if ($record->status !== LeaveRequest::STATUS_PENDING) {
            return response()->json([
                'success' => false,
                'message' => 'Pengajuan yang sudah diproses admin tidak bisa dibatalkan.',
            ], 422);
        }

        $record->delete();

        return response()->json([
            'success' => true,
            'message' => 'Pengajuan berhasil dibatalkan.',
        ]);
    }

    private function leaveDuration(string $startDate, string $endDate, bool $isHalfDay): int
    {
        if ($isHalfDay) {
            return 1;
        }

        return (int) Carbon::parse($startDate)->diffInDays(Carbon::parse($endDate)) + 1;
    }

    private function requestModel(string $type): ?string
    {
        return match ($type) {
            'leave' => LeaveRequest::class,
            'cash-advance' => CashAdvanceRequest::class,
            default => null,
        };
    }

    private function storeAttachment(Request $request, string $directory): array
    {
        if (!$request->hasFile('attachment')) {
            return [];
        }

        $file = $request->file('attachment');

        return [
            'attachment_path' => $file->store($directory, 'public'),
            'attachment_name' => $file->getClientOriginalName(),
        ];
    }

    private function leaveBalancePayload($employee): array
    {
        $year = now()->year;
        $approved = LeaveRequest::where('employee_id', $employee->id)
            ->where('status', LeaveRequest::STATUS_APPROVED)
            ->whereYear('start_date', $year)
            ->sum('duration_days');
        $pending = LeaveRequest::where('employee_id', $employee->id)
            ->where('status', LeaveRequest::STATUS_PENDING)
            ->whereYear('start_date', $year)
            ->sum('duration_days');
        $quota = (int) ($employee->annual_leave_quota ?? 12);

        return [
            'year' => $year,
            'quota' => $quota,
            'approved_used' => (int) $approved,
            'pending' => (int) $pending,
            'remaining' => max($quota - (int) $approved, 0),
            'available' => max($quota - (int) $approved - (int) $pending, 0),
        ];
    }

    private function cashAdvanceSummaryPayload($employee): array
    {
        $active = CashAdvanceRequest::where('employee_id', $employee->id)
            ->whereIn('status', CashAdvanceRequest::ACTIVE_STATUSES)
            ->sum('outstanding_amount');
        $pending = CashAdvanceRequest::where('employee_id', $employee->id)
            ->where('status', CashAdvanceRequest::STATUS_PENDING)
            ->sum('amount');
        $limit = (int) ($employee->kasbon_limit ?? 0);

        return [
            'limit' => $limit,
            'active_outstanding' => (int) $active,
            'pending_amount' => (int) $pending,
            'remaining_limit' => max($limit - (int) $active - (int) $pending, 0),
        ];
    }

    private function installmentCount(string $repaymentMethod): int
    {
        if (preg_match('/(\d+)/', $repaymentMethod, $matches)) {
            return max((int) $matches[1], 1);
        }

        return 1;
    }
}
