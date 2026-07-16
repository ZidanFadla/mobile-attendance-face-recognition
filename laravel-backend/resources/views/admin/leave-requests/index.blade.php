@extends('layouts.admin')
@section('title', 'Persetujuan Cuti')
@section('page-title', 'Persetujuan Cuti')
@section('page-desc', 'Tinjau dan kontrol pengajuan cuti karyawan')

@section('content')
@php
    $tabs = [
        'pending' => 'Menunggu',
        'approved' => 'Disetujui',
        'rejected' => 'Ditolak',
        'all' => 'Semua',
    ];
    $badgeClass = [
        'pending' => 'bg-amber-100 text-amber-700 rounded-full',
        'approved' => 'bg-emerald-100 text-emerald-700 rounded-full',
        'rejected' => 'bg-red-100 text-red-700 rounded-full',
    ];
@endphp

<div class="space-y-6">
    <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <div class="stat-card">
            <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide">Menunggu</p>
            <p class="mt-2 text-3xl font-bold text-slate-900">{{ $counts['pending'] }}</p>
        </div>
        <div class="stat-card">
            <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide">Disetujui</p>
            <p class="mt-2 text-3xl font-bold text-emerald-600">{{ $counts['approved'] }}</p>
        </div>
        <div class="stat-card">
            <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide">Ditolak</p>
            <p class="mt-2 text-3xl font-bold text-red-600">{{ $counts['rejected'] }}</p>
        </div>
        <div class="stat-card">
            <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide">Total</p>
            <p class="mt-2 text-3xl font-bold text-slate-900">{{ $counts['all'] }}</p>
        </div>
    </div>

    <div class="flex flex-wrap gap-2">
        @foreach($tabs as $key => $label)
            <a href="{{ route('admin.leave-requests.index', ['status' => $key]) }}"
               class="px-4 py-2 rounded-xl text-sm font-semibold transition {{ $status === $key ? 'bg-gradient-to-r from-[#4F8EF7] to-[#7C5CFC] text-white shadow-lg shadow-blue-500/20' : 'bg-white text-slate-600 border border-gray-100 hover:bg-gray-50' }}">
                {{ $label }} <span class="ml-1 text-xs opacity-80">{{ $counts[$key] }}</span>
            </a>
        @endforeach
    </div>

    <div class="space-y-4">
        @forelse($leaveRequests as $requestItem)
            <div class="clay-panel p-5">
                <div class="flex flex-col xl:flex-row xl:items-start xl:justify-between gap-5">
                    <div class="flex-1 min-w-0">
                        <div class="flex flex-wrap items-center gap-2">
                            <h3 class="text-base font-bold text-slate-900">{{ $requestItem->employee->name ?? 'Karyawan' }}</h3>
                            <span class="inline-flex px-2.5 py-1 rounded-full text-xs font-bold {{ $badgeClass[$requestItem->status] ?? 'bg-gray-100 text-slate-700' }}">
                                {{ ucfirst($requestItem->status) }}
                            </span>
                        </div>

                        <div class="mt-3 grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-3 text-sm">
                            <div>
                                <p class="text-xs text-slate-400 font-semibold uppercase">Jenis</p>
                                <p class="mt-1 font-semibold text-slate-800">{{ $requestItem->leave_type }}</p>
                            </div>
                            <div>
                                <p class="text-xs text-slate-400 font-semibold uppercase">Tanggal</p>
                                <p class="mt-1 font-semibold text-slate-800">
                                    {{ $requestItem->start_date->format('d M Y') }} - {{ $requestItem->end_date->format('d M Y') }}
                                </p>
                            </div>
                            <div>
                                <p class="text-xs text-slate-400 font-semibold uppercase">Durasi</p>
                                <p class="mt-1 font-semibold text-slate-800">{{ $requestItem->is_half_day ? 'Setengah hari' : $requestItem->duration_days . ' hari' }}</p>
                            </div>
                            <div>
                                <p class="text-xs text-slate-400 font-semibold uppercase">Diajukan</p>
                                <p class="mt-1 font-semibold text-slate-800">{{ $requestItem->created_at->format('d M Y, H:i') }}</p>
                            </div>
                        </div>

                        <div class="mt-4 grid grid-cols-1 lg:grid-cols-4 gap-3">
                            <div class="rounded-xl bg-gray-50 p-4">
                                <p class="text-xs font-semibold uppercase text-slate-400 mb-1">Alasan</p>
                                <p class="text-sm text-slate-700 whitespace-pre-line">{{ $requestItem->reason }}</p>
                            </div>
                            <div class="rounded-xl bg-gray-50 p-4">
                                <p class="text-xs font-semibold uppercase text-slate-400 mb-1">Kontak</p>
                                <p class="text-sm text-slate-700">{{ $requestItem->contact_during_leave ?: '-' }}</p>
                            </div>
                            <div class="rounded-xl bg-gray-50 p-4">
                                <p class="text-xs font-semibold uppercase text-slate-400 mb-1">Serah Terima</p>
                                <p class="text-sm text-slate-700 whitespace-pre-line">{{ $requestItem->handover_note ?: '-' }}</p>
                            </div>
                            <div class="rounded-xl bg-gray-50 p-4">
                                <p class="text-xs font-semibold uppercase text-slate-400 mb-1">Lampiran</p>
                                @if($requestItem->attachment_path)
                                    <a href="{{ asset('storage/' . $requestItem->attachment_path) }}" target="_blank" class="text-sm font-semibold text-emerald-700 hover:underline">
                                        {{ $requestItem->attachment_name ?: 'Buka lampiran' }}
                                    </a>
                                @else
                                    <p class="text-sm text-slate-700">-</p>
                                @endif
                            </div>
                        </div>

                        @if($requestItem->reviewed_at)
                            <p class="mt-3 text-xs text-slate-500">
                                Diproses oleh {{ $requestItem->reviewer->name ?? 'Admin' }} pada {{ $requestItem->reviewed_at->format('d M Y, H:i') }}
                                @if($requestItem->admin_note) - Catatan: {{ $requestItem->admin_note }} @endif
                            </p>
                        @endif
                    </div>

                    @if($requestItem->status === 'pending')
                        <form method="POST" action="{{ route('admin.leave-requests.update', $requestItem) }}" class="w-full xl:w-80 space-y-3">
                            @csrf
                            @method('PUT')
                            <textarea name="admin_note" rows="3" class="input-field resize-none" placeholder="Catatan admin (opsional)">{{ old('admin_note') }}</textarea>
                            <div class="grid grid-cols-2 gap-2">
                                <button type="submit" name="status" value="approved" class="btn-primary">Setujui</button>
                                <button type="submit" name="status" value="rejected" class="px-4 py-2.5 btn-danger">Tolak</button>
                            </div>
                        </form>
                    @endif
                </div>
            </div>
        @empty
            <div class="empty-state text-center">
                <p class="text-slate-500 font-medium">Belum ada pengajuan cuti.</p>
            </div>
        @endforelse
    </div>

    @if($leaveRequests->hasPages())
        <div>{{ $leaveRequests->links() }}</div>
    @endif
</div>
@endsection
