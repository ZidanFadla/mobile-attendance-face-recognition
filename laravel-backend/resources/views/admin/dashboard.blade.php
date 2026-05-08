@extends('layouts.admin')
@section('title', 'Dashboard')
@section('page-title', 'Dashboard')
@section('page-desc', 'Ringkasan aktivitas absensi karyawan')

@section('content')
<div class="space-y-8">
    {{-- Welcome Banner --}}
    <div class="bg-gradient-to-r from-emerald-600 to-teal-500 rounded-2xl p-8 text-white relative overflow-hidden">
        <div class="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full -translate-y-1/2 translate-x-1/4"></div>
        <div class="absolute bottom-0 right-32 w-32 h-32 bg-white/5 rounded-full translate-y-1/2"></div>
        <div class="relative z-10">
            <h2 class="text-2xl font-bold">Selamat Datang, {{ auth()->user()->name ?? 'Admin' }} 👋</h2>
            <p class="text-emerald-100 mt-2 text-sm">Kelola absensi karyawan outsourcing dengan mudah dan efisien.</p>
        </div>
    </div>

    {{-- Stat Cards --}}
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        {{-- Total Karyawan --}}
        <div class="stat-card group">
            <div class="flex items-start justify-between">
                <div>
                    <p class="text-sm font-medium text-gray-500">Total Karyawan</p>
                    <p class="text-3xl font-extrabold text-gray-900 mt-2">{{ $totalKaryawan }}</p>
                    <a href="{{ route('admin.employees.index') }}" class="text-xs text-emerald-600 font-medium mt-3 inline-flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                        Lihat detail <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path></svg>
                    </a>
                </div>
                <div class="w-12 h-12 bg-blue-50 rounded-2xl flex items-center justify-center">
                    <svg class="w-6 h-6 text-blue-500" fill="currentColor" viewBox="0 0 20 20"><path d="M9 6a3 3 0 11-6 0 3 3 0 016 0zM17 6a3 3 0 11-6 0 3 3 0 016 0zM12.93 17c.046-.327.07-.66.07-1a6.97 6.97 0 00-1.5-4.33A5 5 0 0119 16v1h-6.07zM6 11a5 5 0 015 5v1H1v-1a5 5 0 015-5z"></path></svg>
                </div>
            </div>
        </div>

        {{-- Hadir --}}
        <div class="stat-card group">
            <div class="flex items-start justify-between">
                <div>
                    <p class="text-sm font-medium text-gray-500">Hadir Hari Ini</p>
                    <p class="text-3xl font-extrabold text-gray-900 mt-2">{{ $hadirHariIni }}</p>
                    <a href="{{ route('admin.attendance.index') }}" class="text-xs text-emerald-600 font-medium mt-3 inline-flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                        Lihat detail <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path></svg>
                    </a>
                </div>
                <div class="w-12 h-12 bg-emerald-50 rounded-2xl flex items-center justify-center">
                    <svg class="w-6 h-6 text-emerald-500" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path></svg>
                </div>
            </div>
        </div>

        {{-- Terlambat --}}
        <div class="stat-card group">
            <div class="flex items-start justify-between">
                <div>
                    <p class="text-sm font-medium text-gray-500">Terlambat</p>
                    <p class="text-3xl font-extrabold text-gray-900 mt-2">{{ $terlatHariIni }}</p>
                    <span class="text-xs text-gray-400 mt-3 inline-block">Hari ini</span>
                </div>
                <div class="w-12 h-12 bg-amber-50 rounded-2xl flex items-center justify-center">
                    <svg class="w-6 h-6 text-amber-500" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"></path></svg>
                </div>
            </div>
        </div>

        {{-- Lembur --}}
        <div class="stat-card group">
            <div class="flex items-start justify-between">
                <div>
                    <p class="text-sm font-medium text-gray-500">Lembur</p>
                    <p class="text-3xl font-extrabold text-gray-900 mt-2">{{ $lemburHariIni }}</p>
                    <span class="text-xs text-gray-400 mt-3 inline-block">Hari ini</span>
                </div>
                <div class="w-12 h-12 bg-purple-50 rounded-2xl flex items-center justify-center">
                    <svg class="w-6 h-6 text-purple-500" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd"></path></svg>
                </div>
            </div>
        </div>
    </div>

    {{-- Absensi Terbaru --}}
    <div class="table-container">
        <div class="px-6 py-5 border-b border-gray-100 flex items-center justify-between">
            <div>
                <h3 class="text-base font-bold text-gray-900">Aktivitas Terbaru</h3>
                <p class="text-xs text-gray-500 mt-0.5">10 absensi terakhir</p>
            </div>
            <a href="{{ route('admin.attendance.index') }}" class="text-sm text-emerald-600 font-semibold hover:text-emerald-700">
                Lihat Semua →
            </a>
        </div>
        <div class="overflow-x-auto">
            <table class="w-full text-sm">
                <thead>
                    <tr class="bg-gray-50/80">
                        <th class="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Karyawan</th>
                        <th class="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Tipe</th>
                        <th class="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Waktu</th>
                        <th class="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Status</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-50">
                    @forelse($recentAttendance as $att)
                        <tr class="hover:bg-gray-50/50 transition-colors">
                            <td class="px-6 py-4">
                                <div class="flex items-center gap-3">
                                    <div class="w-8 h-8 bg-emerald-100 rounded-lg flex items-center justify-center">
                                        <span class="text-xs font-bold text-emerald-700">{{ substr($att->name, 0, 1) }}</span>
                                    </div>
                                    <span class="font-medium text-gray-900">{{ $att->name }}</span>
                                </div>
                            </td>
                            <td class="px-6 py-4">
                                <span class="inline-flex px-2.5 py-1 rounded-lg text-xs font-semibold
                                    {{ $att->type === 'Masuk' ? 'bg-emerald-100 text-emerald-700' : 'bg-blue-100 text-blue-700' }}">
                                    {{ $att->type }}
                                </span>
                            </td>
                            <td class="px-6 py-4 text-gray-500">{{ \Carbon\Carbon::parse($att->timestamp)->format('d M Y, H:i') }}</td>
                            <td class="px-6 py-4">
                                @if($att->status === 'tepat_waktu')
                                    <span class="inline-flex items-center gap-1 text-emerald-600 text-xs font-semibold">
                                        <span class="w-1.5 h-1.5 bg-emerald-500 rounded-full"></span> Tepat Waktu
                                    </span>
                                @elseif($att->status === 'telat')
                                    <span class="inline-flex items-center gap-1 text-red-600 text-xs font-semibold">
                                        <span class="w-1.5 h-1.5 bg-red-500 rounded-full"></span> Terlambat
                                    </span>
                                @else
                                    <span class="text-gray-400 text-xs">{{ $att->status ?? '-' }}</span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="4" class="px-6 py-12 text-center">
                                <div class="text-gray-400">
                                    <svg class="w-12 h-12 mx-auto mb-3 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path></svg>
                                    <p class="text-sm">Belum ada data absensi</p>
                                </div>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection