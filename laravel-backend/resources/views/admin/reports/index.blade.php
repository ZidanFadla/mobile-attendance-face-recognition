@extends('layouts.admin')
@section('title', 'Rekap & Laporan')
@section('page-title', 'Rekap & Laporan')
@section('page-desc', 'Ringkasan absensi karyawan')

@section('content')
<div class="space-y-5">
    {{-- Tabs --}}
    <div class="bg-white rounded-2xl border border-gray-100 shadow-sm">
        <div class="px-2 pt-2">
            <nav class="flex gap-1 bg-gray-100 p-1 rounded-xl">
                @foreach(['harian' => 'Harian', 'bulanan' => 'Bulanan', 'tahunan' => 'Tahunan', 'lembur' => 'Lembur'] as $key => $label)
                    <a href="{{ route('admin.reports.index', ['tab' => $key]) }}"
                       class="flex-1 text-center px-4 py-2.5 text-sm font-semibold rounded-lg transition-all duration-200
                              {{ $tab === $key ? 'bg-white text-emerald-700 shadow-sm' : 'text-gray-500 hover:text-gray-700' }}">
                        {{ $label }}
                    </a>
                @endforeach
            </nav>
        </div>

        <div class="p-6">
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
