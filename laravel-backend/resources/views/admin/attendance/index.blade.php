@extends('layouts.admin')
@section('title', 'Data Absensi')
@section('page-title', 'Data Absensi')
@section('page-desc', 'Monitoring absensi harian karyawan')

@section('content')
<div class="space-y-5">
    {{-- Filter --}}
    <div class="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
        <form method="GET" class="flex flex-col sm:flex-row gap-3">
            <div class="flex-1">
                <label class="block text-xs font-semibold text-gray-500 mb-1.5">Tanggal</label>
                <input type="date" name="date" value="{{ $date }}" class="input-field">
            </div>
            <div class="flex-1">
                <label class="block text-xs font-semibold text-gray-500 mb-1.5">Cari Karyawan</label>
                <input type="text" name="search" value="{{ $search }}" placeholder="Nama karyawan..." class="input-field">
            </div>
            <div class="flex items-end gap-2">
                <button type="submit" class="btn-primary">Filter</button>
                <a href="{{ route('admin.attendance.index') }}" class="btn-secondary">Reset</a>
            </div>
        </form>
    </div>

    {{-- Table --}}
    <div class="table-container">
        <div class="px-6 py-5 border-b border-gray-100">
            <h3 class="text-sm font-bold text-gray-900">
                Absensi {{ \Carbon\Carbon::parse($date)->translatedFormat('l, d F Y') }}
                <span class="text-gray-400 font-normal ml-1">({{ count($grouped) }} karyawan)</span>
            </h3>
        </div>
        <div class="overflow-x-auto">
            <table class="w-full text-sm">
                <thead>
                    <tr class="bg-gray-50/80">
                        <th class="px-6 py-3.5 text-left text-xs font-semibold text-gray-500 uppercase">Karyawan</th>
                        <th class="px-6 py-3.5 text-center text-xs font-semibold text-gray-500 uppercase">Masuk</th>
                        <th class="px-6 py-3.5 text-center text-xs font-semibold text-gray-500 uppercase">Status</th>
                        <th class="px-6 py-3.5 text-center text-xs font-semibold text-gray-500 uppercase">Pulang</th>
                        <th class="px-6 py-3.5 text-center text-xs font-semibold text-gray-500 uppercase">Lembur</th>
                        <th class="px-6 py-3.5 text-left text-xs font-semibold text-gray-500 uppercase">Lokasi</th>
                        <th class="px-6 py-3.5 text-right text-xs font-semibold text-gray-500 uppercase">Edit</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-50">
                    @forelse($grouped as $data)
                        <tr class="hover:bg-gray-50/50 transition-colors">
                            <td class="px-6 py-4">
                                <div class="flex items-center gap-3">
                                    <div class="w-8 h-8 bg-emerald-100 rounded-lg flex items-center justify-center">
                                        <span class="text-xs font-bold text-emerald-700">{{ substr($data['name'], 0, 1) }}</span>
                                    </div>
                                    <div>
                                        <p class="font-semibold text-gray-900">{{ $data['name'] }}</p>
                                        <p class="text-xs text-gray-400">{{ $data['jabatan'] }}</p>
                                    </div>
                                </div>
                            </td>
                            <td class="px-6 py-4 text-center font-mono font-semibold text-gray-900">{{ $data['masuk'] ?? '-' }}</td>
                            <td class="px-6 py-4 text-center">
                                @if($data['status_masuk'] === 'tepat_waktu')
                                    <span class="inline-flex px-2.5 py-1 rounded-lg text-xs font-semibold bg-emerald-100 text-emerald-700">Tepat</span>
                                @elseif($data['status_masuk'] === 'telat')
                                    <span class="inline-flex px-2.5 py-1 rounded-lg text-xs font-semibold bg-red-100 text-red-700">Telat</span>
                                @else
                                    <span class="text-gray-300">—</span>
                                @endif
                            </td>
                            <td class="px-6 py-4 text-center font-mono font-semibold text-gray-900">{{ $data['pulang'] ?? '-' }}</td>
                            <td class="px-6 py-4 text-center">
                                @if($data['is_lembur'])
                                    <span class="inline-flex px-2.5 py-1 rounded-lg text-xs font-semibold bg-purple-100 text-purple-700">Lembur</span>
                                @else
                                    <span class="text-gray-300">—</span>
                                @endif
                            </td>
                            <td class="px-6 py-4 text-gray-400 text-xs max-w-[120px] truncate">{{ $data['location'] ?? '-' }}</td>
                            <td class="px-6 py-4 text-right">
                                @if($data['masuk_id'])
                                    <form method="POST" action="{{ route('admin.attendance.update', $data['masuk_id']) }}" class="inline">
                                        @csrf @method('PUT')
                                        <select name="status" onchange="this.form.submit()" class="text-xs border-gray-200 rounded-lg py-1.5 px-2 focus:ring-emerald-500 focus:border-emerald-500">
                                            <option value="tepat_waktu" {{ $data['status_masuk'] === 'tepat_waktu' ? 'selected' : '' }}>Tepat</option>
                                            <option value="telat" {{ $data['status_masuk'] === 'telat' ? 'selected' : '' }}>Telat</option>
                                        </select>
                                    </form>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="px-6 py-12 text-center text-gray-400">
                                <svg class="w-12 h-12 mx-auto mb-3 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path></svg>
                                <p class="text-sm">Tidak ada data absensi pada tanggal ini</p>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection