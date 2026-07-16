@php
    $navItems = [
        ['label' => 'Dashboard', 'route' => 'admin.dashboard', 'active' => 'admin.dashboard', 'icon' => 'layout-dashboard'],
        ['label' => 'Data Karyawan', 'route' => 'admin.employees.index', 'active' => 'admin.employees.*', 'icon' => 'users'],
        ['label' => 'Data Absensi', 'route' => 'admin.attendance.index', 'active' => 'admin.attendance.*', 'icon' => 'calendar-check'],
        ['label' => 'Rekap & Laporan', 'route' => 'admin.reports.index', 'active' => 'admin.reports.*', 'icon' => 'bar-chart'],
        ['label' => 'Pesan', 'route' => 'admin.messages.index', 'active' => 'admin.messages.*', 'icon' => 'mail'],
        ['label' => 'Persetujuan Cuti', 'route' => 'admin.leave-requests.index', 'active' => 'admin.leave-requests.*', 'icon' => 'calendar-days'],
        ['label' => 'Persetujuan Kasbon', 'route' => 'admin.cash-advance-requests.index', 'active' => 'admin.cash-advance-requests.*', 'icon' => 'wallet'],
    ];
    $unreadCount = $adminUnreadCount ?? 0;
    $pendingLeaveCount = $adminPendingLeaveCount ?? 0;
    $pendingCashAdvanceCount = $adminPendingCashAdvanceCount ?? 0;
@endphp


<div x-cloak x-show="sidebarOpen" x-transition.opacity class="fixed inset-0 z-40 bg-slate-900/30 backdrop-blur-sm lg:hidden" @click="sidebarOpen = false"></div>

<aside
    class="fixed inset-y-0 left-0 z-50 w-80 max-w-[88vw] -translate-x-full p-4 transition-transform duration-300 lg:translate-x-0"
    :class="sidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'"
>
    <div class="flex h-full flex-col clay-panel px-4 py-5" x-data="{ menuSearch: '' }">
        <div class="mb-6 flex items-center justify-between px-2">
            <a href="{{ route('admin.dashboard') }}" class="flex items-center gap-3">
                <div class="flex h-12 w-12 items-center justify-center rounded-3xl bg-gradient-to-br from-[#4F8EF7] to-[#7C5CFC] text-white shadow-lg shadow-blue-500/20">
                    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12.75 11.25 15 15 9.75M8.25 21h7.5A2.25 2.25 0 0 0 18 18.75V5.25A2.25 2.25 0 0 0 15.75 3h-7.5A2.25 2.25 0 0 0 6 5.25v13.5A2.25 2.25 0 0 0 8.25 21Z"/></svg>
                </div>
                <div>
                    <h1 class="text-lg font-extrabold tracking-tight text-slate-900">Absensi OB</h1>
                    <p class="text-xs font-semibold text-slate-500">Attendance Suite</p>
                </div>
            </a>
            <button class="rounded-2xl p-2 text-slate-500 hover:bg-slate-100 lg:hidden" @click="sidebarOpen = false" aria-label="Tutup menu">
                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18 18 6M6 6l12 12"/></svg>
            </button>
        </div>

        <div class="mb-5 px-2">
            <div class="relative">
                <svg class="pointer-events-none absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24" x-html="iconPath('search')"></svg>
                <input type="text" placeholder="Cari menu..." class="input-field !py-2.5 !pl-11" aria-label="Cari menu" x-model="menuSearch">
            </div>
        </div>

        <nav class="min-h-0 flex-1 space-y-1 overflow-y-auto px-1">
            <p class="px-4 pb-2 text-[11px] font-extrabold uppercase tracking-[.18em] text-slate-400">Menu Utama</p>
            @foreach($navItems as $item)
                @php
                    $badge = null;
                    if ($item['route'] === 'admin.messages.index' && $unreadCount > 0) $badge = $unreadCount;
                    if ($item['route'] === 'admin.leave-requests.index' && $pendingLeaveCount > 0) $badge = $pendingLeaveCount;
                    if ($item['route'] === 'admin.cash-advance-requests.index' && $pendingCashAdvanceCount > 0) $badge = $pendingCashAdvanceCount;
                @endphp
                <a href="{{ route($item['route']) }}" class="sidebar-link {{ request()->routeIs($item['active']) ? 'sidebar-link-active' : '' }}" @click="sidebarOpen = false" x-show="!menuSearch || '{{ strtolower($item['label']) }}'.includes(menuSearch.toLowerCase())">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round" x-html="iconPath('{{ $item['icon'] }}')"></svg>
                    <span class="min-w-0 flex-1 truncate">{{ $item['label'] }}</span>
                    @if($badge)
                        <span class="rounded-full bg-amber-100 px-2 py-0.5 text-[11px] font-extrabold text-amber-700">{{ $badge }}</span>
                    @endif
                </a>
            @endforeach
        </nav>

        <div class="mt-5 rounded-3xl bg-white/70 p-3 shadow-inner shadow-white">
            <div class="flex items-center gap-3">
                <div class="flex h-11 w-11 items-center justify-center rounded-2xl bg-gradient-to-br from-[#4F8EF7] to-[#7C5CFC] text-sm font-extrabold text-white">
                    {{ substr(auth()->user()->name ?? 'A', 0, 1) }}
                </div>
                <div class="min-w-0 flex-1">
                    <p class="truncate text-sm font-extrabold text-slate-900">{{ auth()->user()->name ?? 'Admin' }}</p>
                    <p class="text-xs font-semibold text-slate-500">Administrator</p>
                </div>
                <form method="POST" action="{{ route('logout') }}">
                    @csrf
                    <button type="submit" class="rounded-2xl p-2 text-slate-400 transition hover:bg-red-50 hover:text-red-500" title="Logout" aria-label="Logout">
                        <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-linecap="round" stroke-linejoin="round" x-html="iconPath('log-out')"></svg>
                    </button>
                </form>
            </div>
        </div>
    </div>
</aside>
