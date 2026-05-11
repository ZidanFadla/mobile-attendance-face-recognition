@extends('layouts.admin')
@section('title', 'Persetujuan Kasbon')
@section('page-title', 'Persetujuan Kasbon')
@section('page-desc', 'Tinjau dan kontrol pengajuan kasbon karyawan')

@section('content')
@php
    $tabs = [
        'pending' => 'Menunggu',
        'approved' => 'Disetujui',
        'disbursed' => 'Dicairkan',
        'installment' => 'Cicilan',
        'paid' => 'Lunas',
        'rejected' => 'Ditolak',
        'all' => 'Semua',
    ];
    $badgeClass = [
        'pending' => 'bg-amber-100 text-amber-700',
        'approved' => 'bg-emerald-100 text-emerald-700',
        'disbursed' => 'bg-blue-100 text-blue-700',
        'installment' => 'bg-indigo-100 text-indigo-700',
        'paid' => 'bg-gray-100 text-gray-700',
        'rejected' => 'bg-red-100 text-red-700',
    ];
@endphp

<div class="space-y-6">
    <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <div class="stat-card">
            <p class="text-xs font-semibold text-gray-500 uppercase tracking-wide">Menunggu</p>
            <p class="mt-2 text-3xl font-bold text-gray-900">{{ $counts['pending'] }}</p>
        </div>
        <div class="stat-card">
            <p class="text-xs font-semibold text-gray-500 uppercase tracking-wide">Disetujui</p>
            <p class="mt-2 text-3xl font-bold text-emerald-600">{{ $counts['approved'] }}</p>
        </div>
        <div class="stat-card">
            <p class="text-xs font-semibold text-gray-500 uppercase tracking-wide">Aktif</p>
            <p class="mt-2 text-3xl font-bold text-blue-600">{{ $counts['approved'] + $counts['disbursed'] + $counts['installment'] }}</p>
        </div>
        <div class="stat-card">
            <p class="text-xs font-semibold text-gray-500 uppercase tracking-wide">Lunas</p>
            <p class="mt-2 text-3xl font-bold text-gray-900">{{ $counts['paid'] }}</p>
        </div>
    </div>

    <div class="flex flex-wrap gap-2">
        @foreach($tabs as $key => $label)
            <a href="{{ route('admin.cash-advance-requests.index', ['status' => $key]) }}"
               class="px-4 py-2 rounded-xl text-sm font-semibold transition {{ $status === $key ? 'bg-emerald-600 text-white' : 'bg-white text-gray-600 border border-gray-100 hover:bg-gray-50' }}">
                {{ $label }} <span class="ml-1 text-xs opacity-80">{{ $counts[$key] }}</span>
            </a>
        @endforeach
    </div>

    <div class="space-y-4">
        @forelse($cashAdvanceRequests as $requestItem)
            <div class="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
                <div class="flex flex-col xl:flex-row xl:items-start xl:justify-between gap-5">
                    <div class="flex-1 min-w-0">
                        <div class="flex flex-wrap items-center gap-2">
                            <h3 class="text-base font-bold text-gray-900">{{ $requestItem->employee->name ?? 'Karyawan' }}</h3>
                            <span class="inline-flex px-2.5 py-1 rounded-lg text-xs font-semibold {{ $badgeClass[$requestItem->status] ?? 'bg-gray-100 text-gray-700' }}">
                                {{ ucfirst($requestItem->status) }}
                            </span>
                        </div>

                        <div class="mt-3 grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-3 text-sm">
                            <div>
                                <p class="text-xs text-gray-400 font-semibold uppercase">Nominal</p>
                                <p class="mt-1 font-bold text-gray-900">Rp {{ number_format($requestItem->amount, 0, ',', '.') }}</p>
                            </div>
                            <div>
                                <p class="text-xs text-gray-400 font-semibold uppercase">Tujuan</p>
                                <p class="mt-1 font-semibold text-gray-800">{{ $requestItem->purpose }}</p>
                            </div>
                            <div>
                                <p class="text-xs text-gray-400 font-semibold uppercase">Dibutuhkan</p>
                                <p class="mt-1 font-semibold text-gray-800">{{ $requestItem->needed_date->format('d M Y') }}</p>
                            </div>
                            <div>
                                <p class="text-xs text-gray-400 font-semibold uppercase">Limit Karyawan</p>
                                <p class="mt-1 font-semibold text-gray-800">Rp {{ number_format($requestItem->employee->kasbon_limit ?? 0, 0, ',', '.') }}</p>
                            </div>
                        </div>
                        <div class="mt-3 grid grid-cols-1 md:grid-cols-3 gap-3 text-sm">
                            <div class="rounded-xl bg-gray-50 p-4">
                                <p class="text-xs text-gray-400 font-semibold uppercase">Sisa Kasbon</p>
                                <p class="mt-1 font-bold text-gray-900">Rp {{ number_format($requestItem->outstanding_amount, 0, ',', '.') }}</p>
                            </div>
                            <div class="rounded-xl bg-gray-50 p-4">
                                <p class="text-xs text-gray-400 font-semibold uppercase">Cicilan</p>
                                <p class="mt-1 font-semibold text-gray-800">{{ $requestItem->installment_paid }} / {{ max($requestItem->installment_count, 1) }} kali</p>
                            </div>
                            <div class="rounded-xl bg-gray-50 p-4">
                                <p class="text-xs text-gray-400 font-semibold uppercase">Dicairkan</p>
                                <p class="mt-1 font-semibold text-gray-800">{{ $requestItem->disbursed_at ? $requestItem->disbursed_at->format('d M Y, H:i') : '-' }}</p>
                            </div>
                        </div>

                        <div class="mt-4 grid grid-cols-1 lg:grid-cols-4 gap-3">
                            <div class="rounded-xl bg-gray-50 p-4">
                                <p class="text-xs font-semibold uppercase text-gray-400 mb-1">Alasan</p>
                                <p class="text-sm text-gray-700 whitespace-pre-line">{{ $requestItem->reason }}</p>
                            </div>
                            <div class="rounded-xl bg-gray-50 p-4">
                                <p class="text-xs font-semibold uppercase text-gray-400 mb-1">Pengembalian</p>
                                <p class="text-sm text-gray-700">{{ $requestItem->repayment_method }}</p>
                            </div>
                            <div class="rounded-xl bg-gray-50 p-4">
                                <p class="text-xs font-semibold uppercase text-gray-400 mb-1">Pencairan</p>
                                <p class="text-sm text-gray-700">
                                    {{ $requestItem->disbursement_method ?: '-' }}
                                    @if($requestItem->account_number)
                                        <span class="block mt-1">{{ $requestItem->account_number }}</span>
                                    @endif
                                </p>
                            </div>
                            <div class="rounded-xl bg-gray-50 p-4">
                                <p class="text-xs font-semibold uppercase text-gray-400 mb-1">Lampiran</p>
                                @if($requestItem->attachment_path)
                                    <a href="{{ asset('storage/' . $requestItem->attachment_path) }}" target="_blank" class="text-sm font-semibold text-emerald-700 hover:underline">
                                        {{ $requestItem->attachment_name ?: 'Buka lampiran' }}
                                    </a>
                                @else
                                    <p class="text-sm text-gray-700">-</p>
                                @endif
                            </div>
                        </div>

                        @if($requestItem->reviewed_at)
                            <p class="mt-3 text-xs text-gray-500">
                                Diproses oleh {{ $requestItem->reviewer->name ?? 'Admin' }} pada {{ $requestItem->reviewed_at->format('d M Y, H:i') }}
                                @if($requestItem->admin_note) - Catatan: {{ $requestItem->admin_note }} @endif
                            </p>
                        @endif
                    </div>

                    @if($requestItem->status === 'pending')
                        <form method="POST" action="{{ route('admin.cash-advance-requests.update', $requestItem) }}" class="w-full xl:w-80 space-y-3">
                            @csrf
                            @method('PUT')
                            <textarea name="admin_note" rows="3" class="input-field resize-none" placeholder="Catatan admin (opsional)">{{ old('admin_note') }}</textarea>
                            <div class="grid grid-cols-2 gap-2">
                                <button type="submit" name="status" value="approved" class="btn-primary">Setujui</button>
                                <button type="submit" name="status" value="rejected" class="px-4 py-2.5 bg-red-600 text-white text-sm font-semibold rounded-xl hover:bg-red-700 transition">Tolak</button>
                            </div>
                        </form>
                    @endif
                    @if(in_array($requestItem->status, ['approved', 'disbursed', 'installment']))
                        <form method="POST" action="{{ route('admin.cash-advance-requests.progress', $requestItem) }}" class="w-full xl:w-80 space-y-3">
                            @csrf
                            @method('PUT')
                            <textarea name="admin_note" rows="3" class="input-field resize-none" placeholder="Catatan status (opsional)">{{ old('admin_note') }}</textarea>
                            @php
                                $currentOutstanding = $requestItem->outstanding_amount > 0 ? $requestItem->outstanding_amount : $requestItem->amount;
                                $remainingInstallments = max($requestItem->installment_count - $requestItem->installment_paid, 1);
                                $suggestedInstallmentAmount = min((int) ceil($currentOutstanding / $remainingInstallments), $currentOutstanding);
                            @endphp
                            <div>
                                <label class="block mb-1 text-xs font-semibold uppercase text-gray-400">Nominal Cicilan</label>
                                <input
                                    type="number"
                                    name="installment_amount"
                                    min="1"
                                    max="{{ $currentOutstanding }}"
                                    value="{{ old('installment_amount', $suggestedInstallmentAmount) }}"
                                    class="input-field"
                                    placeholder="Masukkan nominal cicilan"
                                >
                                <p class="mt-1 text-xs text-gray-500">
                                    Saran: Rp {{ number_format($suggestedInstallmentAmount, 0, ',', '.') }} dari sisa Rp {{ number_format($currentOutstanding, 0, ',', '.') }}
                                </p>
                            </div>
                            <div class="grid grid-cols-1 gap-2">
                                @if($requestItem->status === 'approved')
                                    <button type="submit" name="action" value="disburse" class="btn-primary">Tandai Dicairkan</button>
                                @endif
                                @if(in_array($requestItem->status, ['approved', 'disbursed', 'installment']))
                                    <button type="submit" name="action" value="pay_installment" class="btn-secondary">Simpan Cicilan</button>
                                    <button type="submit" name="action" value="mark_paid" class="px-4 py-2.5 bg-gray-900 text-white text-sm font-semibold rounded-xl hover:bg-gray-800 transition">Tandai Lunas</button>
                                @endif
                            </div>
                        </form>
                    @endif
                </div>
            </div>
        @empty
            <div class="bg-white rounded-2xl border border-gray-100 shadow-sm p-12 text-center">
                <p class="text-gray-500 font-medium">Belum ada pengajuan kasbon.</p>
            </div>
        @endforelse
    </div>

    @if($cashAdvanceRequests->hasPages())
        <div>{{ $cashAdvanceRequests->links() }}</div>
    @endif
</div>
@endsection
