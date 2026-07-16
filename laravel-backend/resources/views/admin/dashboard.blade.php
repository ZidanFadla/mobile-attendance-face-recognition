@extends('layouts.admin')
@section('title', 'Dashboard')
@section('page-title', 'Dashboard')
@section('page-desc', 'Ringkasan aktivitas absensi karyawan')

@section('content')
<div class="space-y-8">
    <section class="clay-panel relative overflow-hidden p-7 sm:p-8">
        <div class="absolute right-8 top-8 hidden h-36 w-36 rounded-full bg-blue-100/80 blur-2xl sm:block"></div>
        <div class="relative grid gap-8 lg:grid-cols-[1.3fr_.7fr] lg:items-center">
            <div>
                <span class="badge-info mb-4">Live attendance command center</span>
                <h2 class="max-w-3xl text-3xl font-black leading-tight tracking-tight text-slate-900 sm:text-4xl">
                    Selamat datang, {{ auth()->user()->name ?? 'Admin' }}.
                </h2>
                <p class="mt-3 max-w-2xl text-sm font-medium leading-7 text-slate-500">
                    Pantau kehadiran, status operasional, dan aktivitas karyawan outsourcing dari satu workspace admin yang ringan dan mudah dipindai.
                </p>
                <div class="mt-6 flex flex-wrap gap-3">
                    <a href="{{ route('admin.attendance.index') }}" class="btn-primary">Pantau Absensi</a>
                    <a href="{{ route('admin.reports.index') }}" class="btn-secondary">Buka Laporan</a>
                </div>
            </div>
            <div class="grid grid-cols-2 gap-3">
                <div class="rounded-3xl bg-white/70 p-4 shadow-inner shadow-white">
                    <p class="text-xs font-bold uppercase tracking-wide text-slate-400">Hari ini</p>
                    <p class="mt-2 text-2xl font-black text-slate-900">{{ now()->translatedFormat('d M') }}</p>
                </div>
                <div class="rounded-3xl bg-white/70 p-4 shadow-inner shadow-white">
                    <p class="text-xs font-bold uppercase tracking-wide text-slate-400">Status</p>
                    <p class="mt-2 text-2xl font-black text-[#22C55E]">Aktif</p>
                </div>
            </div>
        </div>
    </section>

    <section class="grid grid-cols-1 gap-5 sm:grid-cols-2 xl:grid-cols-4">
        <div class="stat-card group">
            <div class="flex items-start justify-between gap-4">
                <div>
                    <p class="text-sm font-bold text-slate-500">Total Karyawan</p>
                    <p class="mt-3 text-4xl font-black tracking-tight text-slate-900">{{ $totalKaryawan }}</p>
                    <p class="mt-2 text-xs font-semibold text-slate-400">Database aktif</p>
                </div>
                <div class="icon-tile text-[#4F8EF7]"><svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/></svg></div>
            </div>
            <a href="{{ route('admin.employees.index') }}" class="mt-5 inline-flex items-center gap-1 text-xs font-extrabold text-[#4F8EF7] opacity-0 transition group-hover:opacity-100">Lihat detail <span>-></span></a>
        </div>

        <div class="stat-card group">
            <div class="flex items-start justify-between gap-4">
                <div>
                    <p class="text-sm font-bold text-slate-500">Hadir Hari Ini</p>
                    <p class="mt-3 text-4xl font-black tracking-tight text-slate-900">{{ $hadirHariIni }}</p>
                    <p class="mt-2 text-xs font-semibold text-emerald-600">Check-in tercatat</p>
                </div>
                <div class="icon-tile text-[#22C55E]"><svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 6 9 17l-5-5"/></svg></div>
            </div>
            <a href="{{ route('admin.attendance.index') }}" class="mt-5 inline-flex items-center gap-1 text-xs font-extrabold text-[#4F8EF7] opacity-0 transition group-hover:opacity-100">Lihat detail <span>-></span></a>
        </div>

        <div class="stat-card">
            <div class="flex items-start justify-between gap-4">
                <div>
                    <p class="text-sm font-bold text-slate-500">Terlambat</p>
                    <p class="mt-3 text-4xl font-black tracking-tight text-slate-900">{{ $terlatHariIni }}</p>
                    <p class="mt-2 text-xs font-semibold text-amber-600">Perlu ditinjau</p>
                </div>
                <div class="icon-tile text-[#F59E0B]"><svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></svg></div>
            </div>
        </div>

        <div class="stat-card">
            <div class="flex items-start justify-between gap-4">
                <div>
                    <p class="text-sm font-bold text-slate-500">Lembur</p>
                    <p class="mt-3 text-4xl font-black tracking-tight text-slate-900">{{ $lemburHariIni }}</p>
                    <p class="mt-2 text-xs font-semibold text-violet-600">Hari ini</p>
                </div>
                <div class="icon-tile text-[#7C5CFC]"><svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M12 8v4l3 3"/><circle cx="12" cy="12" r="10"/></svg></div>
            </div>
        </div>
    </section>

    <section class="table-container">
        <div class="flex items-center justify-between gap-4 px-6 py-5">
            <div>
                <h3 class="text-lg font-black tracking-tight text-slate-900">Aktivitas Terbaru</h3>
                <p class="mt-1 text-sm font-medium text-slate-500">10 absensi terakhir</p>
            </div>
            <a href="{{ route('admin.attendance.index') }}" class="btn-secondary !px-4 !py-2.5">Lihat Semua</a>
        </div>
        <div class="overflow-x-auto">
            <table class="w-full text-sm">
                <thead>
                    <tr>
                        <th class="px-6 py-4 text-left text-xs font-black uppercase tracking-wider text-slate-400">Karyawan</th>
                        <th class="px-6 py-4 text-left text-xs font-black uppercase tracking-wider text-slate-400">Tipe</th>
                        <th class="px-6 py-4 text-left text-xs font-black uppercase tracking-wider text-slate-400">Waktu</th>
                        <th class="px-6 py-4 text-left text-xs font-black uppercase tracking-wider text-slate-400">Status</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100/80">
                    @forelse($recentAttendance as $att)
                        <tr>
                            <td class="px-6 py-4">
                                <div class="flex items-center gap-3">
                                    <div class="flex h-9 w-9 items-center justify-center rounded-2xl bg-blue-50 text-xs font-black text-[#4F8EF7]">{{ substr($att->name, 0, 1) }}</div>
                                    <span class="font-bold text-slate-900">{{ $att->name }}</span>
                                </div>
                            </td>
                            <td class="px-6 py-4"><span class="{{ $att->type === 'Masuk' ? 'badge-success' : 'badge-info' }}">{{ $att->type }}</span></td>
                            <td class="px-6 py-4 font-medium text-slate-500">{{ \Carbon\Carbon::parse($att->timestamp)->format('d M Y, H:i') }}</td>
                            <td class="px-6 py-4">
                                @if($att->status === 'tepat_waktu')
                                    <span class="badge-success">Tepat Waktu</span>
                                @elseif($att->status === 'telat')
                                    <span class="badge-danger">Terlambat</span>
                                @else
                                    <span class="badge-muted">{{ $att->status ?? '-' }}</span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="4" class="px-6 py-12"><div class="empty-state !shadow-none">Belum ada data absensi</div></td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </section>
</div>
@endsection
