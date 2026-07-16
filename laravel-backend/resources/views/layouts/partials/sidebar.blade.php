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
    $unreadCount = \App\Models\Message::where('is_read', false)->count();
    $pendingLeaveCount = \App\Models\LeaveRequest::where('status', 'pending')->count();
    $pendingCashAdvanceCount = \App\Models\CashAdvanceRequest::where('status', 'pending')->count();
@endphp

@once
    @push('scripts')
        <script>
            window.iconPath = function(name) {
                const icons = {
                    'layout-dashboard': '<rect width="7" height="9" x="3" y="3" rx="1"/><rect width="7" height="5" x="14" y="3" rx="1"/><rect width="7" height="9" x="14" y="12" rx="1"/><rect width="7" height="5" x="3" y="16" rx="1"/>',
                    'users': '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
                    'calendar-check': '<path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/><path d="m9 16 2 2 4-4"/>',
                    'bar-chart': '<path d="M3 3v18h18"/><path d="M18 17V9"/><path d="M13 17V5"/><path d="M8 17v-3"/>',
                    'mail': '<rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/>',
                    'calendar-days': '<path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/><path d="M8 14h.01"/><path d="M12 14h.01"/><path d="M16 14h.01"/><path d="M8 18h.01"/><path d="M12 18h.01"/>',
                    'wallet': '<path d="M19 7V4a1 1 0 0 0-1-1H5a3 3 0 0 0 0 6h15a1 1 0 0 1 1 1v4h-3a2 2 0 0 0 0 4h3v2a1 1 0 0 1-1 1H5a3 3 0 0 1-3-3V6"/><path d="M18 14h.01"/>',
                    'log-out': '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="m16 17 5-5-5-5"/><path d="M21 12H9"/>',
                    'search': '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
                };
                return icons[name] || '';
            }
        </script>
    @endpush
@endonce

<div x-show="sidebarOpen" x-transition.opacity class="fixed inset-0 z-40 bg-slate-900/30 backdrop-blur-sm lg:hidden" @click="sidebarOpen = false"></div>

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
