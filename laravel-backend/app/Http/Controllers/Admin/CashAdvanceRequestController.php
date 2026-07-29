<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\CashAdvanceRequest;
use App\Models\Message;
use App\Services\Notifications\FirebaseCloudMessagingService;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class CashAdvanceRequestController extends Controller
{
    public function index(Request $request)
    {
        $status = $request->query('status', 'pending');

        $cashAdvanceRequests = CashAdvanceRequest::with(['employee:id,name,jabatan,phone,kasbon_limit', 'reviewer:id,name'])
            ->when($status !== 'all', fn ($query) => $query->where('status', $status))
            ->latest()
            ->paginate(20)
            ->withQueryString();

        $counts = $this->statusCounts();

        return view('admin.cash-advance-requests.index', compact('cashAdvanceRequests', 'status', 'counts'));
    }

    public function update(Request $request, CashAdvanceRequest $cashAdvanceRequest)
    {
        $validated = $request->validate([
            'status' => ['required', Rule::in(CashAdvanceRequest::REVIEW_STATUSES)],
            'admin_note' => ['nullable', 'string', 'max:2000'],
        ]);

        $payload = [
            'status' => $validated['status'],
            'admin_note' => $validated['admin_note'] ?? null,
            'reviewed_by' => auth()->id(),
            'reviewed_at' => now(),
        ];

        if ($validated['status'] === CashAdvanceRequest::STATUS_APPROVED) {
            $payload['outstanding_amount'] = $cashAdvanceRequest->amount;
        }

        $cashAdvanceRequest->update($payload);
        $this->notifyEmployee($cashAdvanceRequest->fresh());

        $message = $validated['status'] === CashAdvanceRequest::STATUS_APPROVED
            ? 'Pengajuan kasbon berhasil disetujui.'
            : 'Pengajuan kasbon berhasil ditolak.';

        return redirect()->back()->with('success', $message);
    }

    public function progress(Request $request, CashAdvanceRequest $cashAdvanceRequest)
    {
        $validated = $request->validate([
            'action' => ['required', Rule::in(['disburse', 'pay_installment', 'mark_paid'])],
            'admin_note' => ['nullable', 'string', 'max:2000'],
            'installment_amount' => ['nullable', 'integer', 'min:1'],
        ]);

        if ($validated['action'] === 'disburse') {
            $cashAdvanceRequest->update([
                'status' => CashAdvanceRequest::STATUS_DISBURSED,
                'disbursed_at' => now(),
                'admin_note' => $validated['admin_note'] ?? $cashAdvanceRequest->admin_note,
            ]);
        } elseif ($validated['action'] === 'pay_installment') {
            $currentOutstanding = $this->currentOutstanding($cashAdvanceRequest);
            $validated += $request->validate([
                'installment_amount' => ['required', 'integer', 'min:1', 'max:'.$currentOutstanding],
            ]);

            $installmentCount = max((int) $cashAdvanceRequest->installment_count, 1);
            $installmentPaid = min((int) $cashAdvanceRequest->installment_paid + 1, $installmentCount);
            $installmentAmount = (int) $validated['installment_amount'];
            $outstanding = max($currentOutstanding - $installmentAmount, 0);
            $isPaid = $outstanding <= 0;

            $cashAdvanceRequest->update([
                'status' => $isPaid ? CashAdvanceRequest::STATUS_PAID : CashAdvanceRequest::STATUS_INSTALLMENT,
                'installment_paid' => $installmentPaid,
                'outstanding_amount' => $isPaid ? 0 : $outstanding,
                'paid_at' => $isPaid ? now() : null,
                'admin_note' => $validated['admin_note'] ?? $cashAdvanceRequest->admin_note,
            ]);
        } elseif ($validated['action'] === 'mark_paid') {
            $cashAdvanceRequest->update([
                'status' => CashAdvanceRequest::STATUS_PAID,
                'outstanding_amount' => 0,
                'installment_paid' => max((int) $cashAdvanceRequest->installment_count, 1),
                'paid_at' => now(),
                'admin_note' => $validated['admin_note'] ?? $cashAdvanceRequest->admin_note,
            ]);
        }

        $this->notifyEmployee($cashAdvanceRequest->fresh());

        return redirect()->back()->with('success', 'Status kasbon berhasil diperbarui.');
    }

    private function statusCounts(): array
    {
        $counts = collect(CashAdvanceRequest::ADMIN_STATUSES)
            ->mapWithKeys(fn (string $status) => [
                $status => CashAdvanceRequest::where('status', $status)->count(),
            ])
            ->all();

        return [...$counts, 'all' => CashAdvanceRequest::count()];
    }

    private function currentOutstanding(CashAdvanceRequest $cashAdvanceRequest): int
    {
        $outstanding = (int) $cashAdvanceRequest->outstanding_amount;

        return max($outstanding > 0 ? $outstanding : (int) $cashAdvanceRequest->amount, 1);
    }

    private function notifyEmployee(CashAdvanceRequest $cashAdvanceRequest): void
    {
        $statusLabel = match ($cashAdvanceRequest->status) {
            CashAdvanceRequest::STATUS_APPROVED => 'disetujui',
            CashAdvanceRequest::STATUS_REJECTED => 'ditolak',
            CashAdvanceRequest::STATUS_DISBURSED => 'dicairkan',
            CashAdvanceRequest::STATUS_INSTALLMENT => 'diproses cicilan',
            CashAdvanceRequest::STATUS_PAID => 'lunas',
            default => 'diperbarui',
        };
        $note = $cashAdvanceRequest->admin_note ? "\nCatatan admin: {$cashAdvanceRequest->admin_note}" : '';
        $outstanding = number_format($cashAdvanceRequest->outstanding_amount, 0, ',', '.');

        $message = Message::create([
            'sender_id' => auth()->id(),
            'employee_id' => $cashAdvanceRequest->employee_id,
            'type' => 'text',
            'content' => "Status kasbon Rp " . number_format($cashAdvanceRequest->amount, 0, ',', '.') . " telah {$statusLabel}. Sisa kasbon: Rp {$outstanding}.{$note}",
        ]);

        app(FirebaseCloudMessagingService::class)->sendMessageNotification($message);
    }
}
