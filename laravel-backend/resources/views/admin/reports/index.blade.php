@extends('layouts.admin')
@section('title', 'Rekap & Laporan')
@section('page-title', 'Rekap & Laporan')
@section('page-desc', 'Ringkasan absensi karyawan')

@section('content')
@php
    $activeType = $reportType ?? match ($tab) {
        'bulanan' => 'monthly',
        'tahunan' => 'yearly',
        default => 'daily',
    };
    $selectedDate = request('date', $date ?? now()->format('Y-m-d'));
    $selectedMonth = request('month', $month ?? now()->format('Y-m'));
    $selectedYear = request('year', $year ?? now()->year);
    $selectedEmployee = request('employee_id');
    $selectedStatus = request('status', 'all');
@endphp

<div class="space-y-5">
    <div class="clay-panel p-6">
        <div class="mb-5 flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
            <div>
                <h2 class="text-lg font-black tracking-tight text-slate-900">Export Laporan</h2>
                <p class="mt-1 text-sm font-medium text-slate-500">Pilih periode, preview data, lalu export ke Excel atau PDF.</p>
            </div>
            <div class="flex flex-wrap gap-2">
                <button type="submit" form="report-filter-form" formaction="{{ route('admin.reports.export.excel') }}" class="btn-secondary !py-2.5">
                    Export Excel
                </button>
                <button type="submit" form="report-filter-form" formaction="{{ route('admin.reports.export.pdf') }}" class="btn-primary !py-2.5">
                    Export PDF
                </button>
            </div>
        </div>

        <form id="report-filter-form" method="GET" action="{{ route('admin.reports.index') }}" class="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-6">
            <div>
                <label class="mb-1.5 block text-xs font-bold uppercase tracking-wide text-slate-400">Tipe Laporan</label>
                <select name="report_type" class="input-field" onchange="this.form.submit()">
                    <option value="daily" {{ $activeType === 'daily' ? 'selected' : '' }}>Harian</option>
                    <option value="monthly" {{ $activeType === 'monthly' ? 'selected' : '' }}>Bulanan</option>
                    <option value="yearly" {{ $activeType === 'yearly' ? 'selected' : '' }}>Tahunan</option>
                </select>
            </div>
            <div class="{{ $activeType === 'daily' ? '' : 'hidden' }}">
                <label class="mb-1.5 block text-xs font-bold uppercase tracking-wide text-slate-400">Tanggal</label>
                <input type="date" name="date" value="{{ $selectedDate }}" class="input-field">
            </div>
            <div class="{{ $activeType === 'monthly' ? '' : 'hidden' }}">
                <label class="mb-1.5 block text-xs font-bold uppercase tracking-wide text-slate-400">Bulan</label>
                <input type="month" name="month" value="{{ $selectedMonth }}" class="input-field">
            </div>
            <div class="{{ $activeType === 'yearly' ? '' : 'hidden' }}">
                <label class="mb-1.5 block text-xs font-bold uppercase tracking-wide text-slate-400">Tahun</label>
                <select name="year" class="input-field">
                    @for($y = now()->year; $y >= now()->year - 5; $y--)
                        <option value="{{ $y }}" {{ (int) $selectedYear === $y ? 'selected' : '' }}>{{ $y }}</option>
                    @endfor
                </select>
            </div>
            <div>
                <label class="mb-1.5 block text-xs font-bold uppercase tracking-wide text-slate-400">Karyawan</label>
                <select name="employee_id" class="input-field">
                    <option value="">Semua karyawan</option>
                    @foreach($employeesFilter as $employee)
                        <option value="{{ $employee->id }}" {{ (string) $selectedEmployee === (string) $employee->id ? 'selected' : '' }}>
                            {{ $employee->name }}{{ $employee->jabatan ? ' - ' . $employee->jabatan : '' }}
                        </option>
                    @endforeach
                </select>
            </div>
            <div class="{{ $activeType === 'daily' ? '' : 'hidden' }}">
                <label class="mb-1.5 block text-xs font-bold uppercase tracking-wide text-slate-400">Status</label>
                <select name="status" class="input-field">
                    <option value="all" {{ $selectedStatus === 'all' ? 'selected' : '' }}>Semua status</option>
                    <option value="tepat_waktu" {{ $selectedStatus === 'tepat_waktu' ? 'selected' : '' }}>Tepat waktu</option>
                    <option value="telat" {{ $selectedStatus === 'telat' ? 'selected' : '' }}>Terlambat</option>
                </select>
            </div>
            <div class="flex items-end">
                <button type="submit" class="btn-primary w-full !py-3">Preview</button>
            </div>
        </form>
    </div>

    <div class="clay-panel">
        <div class="px-2 pt-2">
            <nav class="flex gap-1 bg-gray-100 p-1 rounded-xl">
                @foreach(['harian' => 'Harian', 'bulanan' => 'Bulanan', 'tahunan' => 'Tahunan', 'lembur' => 'Lembur'] as $key => $label)
                    <a href="{{ route('admin.reports.index', ['tab' => $key]) }}"
                       class="flex-1 text-center px-4 py-2.5 text-sm font-semibold rounded-lg transition-all duration-200
                              {{ $tab === $key ? 'bg-white text-emerald-700 shadow-sm' : 'text-slate-500 hover:text-slate-700' }}">
                        {{ $label }}
                    </a>
                @endforeach
            </nav>
        </div>

        <div class="overflow-x-auto p-6">
            @if($tab === 'harian')
                @include('admin.reports._harian')
            @elseif($tab === 'bulanan')
                @include('admin.reports._bulanan')
            @elseif($tab === 'tahunan')
                @include('admin.reports._tahunan')
            @elseif($tab === 'lembur')
                @include('admin.reports._lembur')
            @endif
        </div>
    </div>
</div>
@endsection
