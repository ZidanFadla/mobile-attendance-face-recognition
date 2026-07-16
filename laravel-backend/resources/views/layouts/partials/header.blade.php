@php
    $unreadCount = \App\Models\Message::where('is_read', false)->count();
    $pendingLeaveCount = \App\Models\LeaveRequest::where('status', 'pending')->count();
    $pendingCashAdvanceCount = \App\Models\CashAdvanceRequest::where('status', 'pending')->count();
    $notificationTotal = $unreadCount + $pendingLeaveCount + $pendingCashAdvanceCount;
@endphp

<header class="sticky top-0 z-30 px-4 pt-4 sm:px-6 lg:px-10 lg:pt-6">
    <div class="mx-auto flex max-w-7xl items-center justify-between gap-4 rounded-3xl bg-white/76 px-4 py-3 shadow-clay backdrop-blur-xl sm:px-5">
        <div class="flex min-w-0 items-center gap-3">
            <button class="rounded-2xl p-3 text-slate-500 transition hover:bg-slate-100 hover:text-slate-900 lg:hidden" @click="sidebarOpen = true" aria-label="Buka menu">
                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/></svg>
            </button>
            <div class="min-w-0">
                <div class="mb-1 flex items-center gap-2 text-xs font-bold text-slate-400">
                    <a href="{{ route('admin.dashboard') }}" class="hover:text-[#4F8EF7]">Admin</a>
                    <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m9 18 6-6-6-6"/></svg>
                    <span class="truncate text-slate-500">@yield('page-title', 'Dashboard')</span>
                </div>
                <h1 class="truncate text-xl font-black tracking-tight text-slate-900 sm:text-2xl lg:text-[32px]">@yield('page-title', 'Dashboard')</h1>
                <p class="mt-1 hidden text-sm font-medium text-slate-500 sm:block">@yield('page-desc', '')</p>
            </div>
        </div>

        <div class="flex shrink-0 items-center gap-2 sm:gap-3">

            <div class="relative" @click.outside="notificationOpen = false">
                <button type="button" class="relative rounded-2xl bg-slate-50/90 p-3 text-slate-500 transition hover:bg-white hover:text-[#4F8EF7]" aria-label="Notifikasi" @click="notificationOpen = !notificationOpen">
                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.4-1.4A2 2 0 0 1 18 14.17V11a6 6 0 1 0-12 0v3.17a2 2 0 0 1-.6 1.43L4 17h5"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 21h4"/></svg>
                    @if($notificationTotal > 0)
                        <span class="absolute -right-1 -top-1 flex h-5 min-w-5 items-center justify-center rounded-full bg-[#EF4444] px-1.5 text-[10px] font-black text-white ring-2 ring-white">{{ $notificationTotal }}</span>
                    @endif
                </button>

                <div x-show="notificationOpen" x-cloak x-transition class="absolute right-0 mt-3 w-80 overflow-hidden rounded-3xl bg-white p-3 shadow-2xl ring-1 ring-black/5">
                    <div class="px-2 pb-3 pt-1">
                        <p class="text-sm font-black text-slate-900">Notifikasi</p>
                        <p class="mt-1 text-xs font-semibold text-slate-500">Ringkasan yang perlu ditinjau admin.</p>
                    </div>
                    <div class="space-y-2">
                        <a href="{{ route('admin.messages.index') }}" class="notification-item">
                            <span class="notification-dot bg-blue-500"></span>
                            <span class="min-w-0 flex-1"><span class="block font-bold">Pesan belum dibaca</span><span class="text-xs text-slate-500">{{ $unreadCount }} pesan</span></span>
                        </a>
                        <a href="{{ route('admin.leave-requests.index', ['status' => 'pending']) }}" class="notification-item">
                            <span class="notification-dot bg-amber-500"></span>
                            <span class="min-w-0 flex-1"><span class="block font-bold">Pengajuan cuti</span><span class="text-xs text-slate-500">{{ $pendingLeaveCount }} menunggu</span></span>
                        </a>
                        <a href="{{ route('admin.cash-advance-requests.index', ['status' => 'pending']) }}" class="notification-item">
                            <span class="notification-dot bg-violet-500"></span>
                            <span class="min-w-0 flex-1"><span class="block font-bold">Pengajuan kasbon</span><span class="text-xs text-slate-500">{{ $pendingCashAdvanceCount }} menunggu</span></span>
                        </a>
                    </div>
                </div>
            </div>

            <a href="{{ route('profile.edit') }}" class="flex items-center gap-3 rounded-2xl bg-white/80 py-2 pl-2 pr-3 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md">
                <span class="flex h-9 w-9 items-center justify-center rounded-2xl bg-gradient-to-br from-[#4F8EF7] to-[#7C5CFC] text-sm font-black text-white">{{ substr(auth()->user()->name ?? 'A', 0, 1) }}</span>
                <span class="hidden text-left sm:block">
                    <span class="block max-w-[130px] truncate text-sm font-extrabold text-slate-900">{{ auth()->user()->name ?? 'Admin' }}</span>
                    <span class="block text-xs font-semibold text-slate-500">Profile</span>
                </span>
            </a>
        </div>
    </div>
</header>
