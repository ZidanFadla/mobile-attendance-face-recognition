<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\LeaveRequest;
use App\Models\Message;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class LeaveRequestController extends Controller
{
    public function index(Request $request)
    {
        $status = $request->query('status', 'pending');

        $leaveRequests = LeaveRequest::with(['employee:id,name,jabatan,phone', 'reviewer:id,name'])
            ->when($status !== 'all', fn ($query) => $query->where('status', $status))
            ->latest()
            ->paginate(20)
            ->withQueryString();

        $counts = $this->statusCounts();

        return view('admin.leave-requests.index', compact('leaveRequests', 'status', 'counts'));
    }

    public function update(Request $request, LeaveRequest $leaveRequest)
    {
        $validated = $request->validate([
            'status' => ['required', Rule::in(LeaveRequest::REVIEW_STATUSES)],
            'admin_note' => ['nullable', 'string', 'max:2000'],
        ]);

        $leaveRequest->update([
            'status' => $validated['status'],
            'admin_note' => $validated['admin_note'] ?? null,
            'reviewed_by' => auth()->id(),
            'reviewed_at' => now(),
        ]);
        $this->notifyEmployee($leaveRequest->fresh());

        $message = $validated['status'] === LeaveRequest::STATUS_APPROVED
            ? 'Pengajuan cuti berhasil disetujui.'
            : 'Pengajuan cuti berhasil ditolak.';

        return redirect()->back()->with('success', $message);
    }

    private function statusCounts(): array
    {
        $counts = collect(LeaveRequest::ADMIN_STATUSES)
            ->mapWithKeys(fn (string $status) => [
                $status => LeaveRequest::where('status', $status)->count(),
            ])
            ->all();

        return [...$counts, 'all' => LeaveRequest::count()];
    }

    private function notifyEmployee(LeaveRequest $leaveRequest): void
    {
        $statusLabel = $leaveRequest->status === LeaveRequest::STATUS_APPROVED ? 'disetujui' : 'ditolak';
        $note = $leaveRequest->admin_note ? "\nCatatan admin: {$leaveRequest->admin_note}" : '';

        Message::create([
            'sender_id' => auth()->id(),
            'employee_id' => $leaveRequest->employee_id,
            'type' => 'text',
            'content' => "Pengajuan cuti {$leaveRequest->leave_type} tanggal {$leaveRequest->start_date->format('d M Y')} - {$leaveRequest->end_date->format('d M Y')} telah {$statusLabel}.{$note}",
        ]);
    }
}
