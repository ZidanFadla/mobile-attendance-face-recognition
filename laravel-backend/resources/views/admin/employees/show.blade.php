@extends('layouts.admin')
@section('title', $employee->name)
@section('page-title', 'Detail Karyawan')
@section('page-desc', 'History absensi ' . $employee->name)

@section('content')
<div class="space-y-6">
    {{-- Profile Card --}}
    <div class="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
        <div class="flex items-center justify-between">
            <div class="flex items-center gap-4">
                <div class="w-16 h-16 bg-gradient-to-br from-emerald-400 to-teal-500 rounded-2xl flex items-center justify-center shadow-lg">
                    <span class="text-white text-2xl font-bold">{{ substr($employee->name, 0, 1) }}</span>
                </div>
                <div>
                    <h2 class="text-xl font-bold text-gray-900">{{ $employee->name }}</h2>
                    <p class="text-sm text-gray-500 mt-0.5">{{ $employee->phone }} · {{ $employee->jabatan ?? '-' }}</p>
                    <div class="flex items-center gap-2 mt-2">
                        @if($employee->face_embedding)
                            <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-xs font-semibold bg-emerald-100 text-emerald-700">
                                <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path></svg>
                                Wajah Terdaftar
                            </span>
                        @else
                            <span class="inline-flex px-2.5 py-1 rounded-lg text-xs font-medium bg-gray-100 text-gray-500">Wajah Belum Terdaftar</span>
                        @endif
                    </div>
                </div>
            </div>
            <a href="{{ route('admin.employees.edit', $employee) }}" class="btn-secondary text-sm">Edit</a>
        </div>
    </div>

    {{-- Ringkasan --}}
    <div class="grid grid-cols-3 gap-4">
        <div class="stat-card text-center">
            <p class="text-3xl font-extrabold text-emerald-600">{{ $totalHadir }}</p>
            <p class="text-xs text-gray-500 mt-1 font-medium">Hadir</p>
        </div>
        <div class="stat-card text-center">
            <p class="text-3xl font-extrabold text-red-500">{{ $totalTerlat }}</p>
            <p class="text-xs text-gray-500 mt-1 font-medium">Terlambat</p>
        </div>
        <div class="stat-card text-center">
            <p class="text-3xl font-extrabold text-purple-600">{{ $totalLembur }}</p>
            <p class="text-xs text-gray-500 mt-1 font-medium">Lembur</p>
        </div>
    </div>

    {{-- Filter & Table --}}
    <div class="table-container">
        <div class="px-6 py-5 border-b border-gray-100 flex items-center justify-between">
            <h3 class="text-sm font-bold text-gray-900">History — {{ \Carbon\Carbon::parse($month)->translatedFormat('F Y') }}</h3>
            <form method="GET" class="flex items-center gap-2">
                <input type="month" name="month" value="{{ $month }}" class="input-field !py-2 !text-xs !w-auto">
                <button type="submit" class="btn-primary !py-2 !text-xs">Filter</button>
            </form>
        </div>
        <div class="overflow-x-auto">
            <table class="w-full text-sm">
                <thead>
                    <tr class="bg-gray-50/80">
                        <th class="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Tanggal</th>
                        <th class="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Tipe</th>
                        <th class="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Jam</th>
                        <th class="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Status</th>
                        <th class="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Lokasi</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-50">
                    @forelse($attendances as $att)
                        <tr class="hover:bg-gray-50/50">
                            <td class="px-6 py-3 text-gray-600">{{ \Carbon\Carbon::parse($att->timestamp)->format('d M Y') }}</td>
                            <td class="px-6 py-3"><span class="px-2 py-0.5 rounded-lg text-xs font-semibold {{ $att->type === 'Masuk' ? 'bg-emerald-100 text-emerald-700' : 'bg-blue-100 text-blue-700' }}">{{ $att->type }}</span></td>
                            <td class="px-6 py-3 font-mono text-gray-900 font-semibold">{{ \Carbon\Carbon::parse($att->timestamp)->format('H:i') }}</td>
                            <td class="px-6 py-3">
                                @if($att->status === 'tepat_waktu') <span class="text-emerald-600 text-xs font-semibold">Tepat Waktu</span>
                                @elseif($att->status === 'telat') <span class="text-red-600 text-xs font-semibold">Terlambat</span>
                                @elseif($att->is_lembur) <span class="text-purple-600 text-xs font-semibold">Lembur</span>
                                @else <span class="text-gray-400 text-xs">{{ $att->status ?? '-' }}</span>
                                @endif
                            </td>
                            <td class="px-6 py-3 text-gray-400 text-xs">{{ $att->location_name ?? '-' }}</td>
                        </tr>
                    @empty
                        <tr><td colspan="5" class="px-6 py-12 text-center text-gray-400 text-sm">Tidak ada data absensi bulan ini</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <a href="{{ route('admin.employees.index') }}" class="inline-flex items-center gap-2 text-sm text-gray-500 hover:text-gray-700">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path></svg>
        Kembali ke Data Karyawan
    </a>
</div>
@endsection