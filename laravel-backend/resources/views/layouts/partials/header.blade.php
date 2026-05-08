<header class="sticky top-0 z-20 bg-white/80 backdrop-blur-xl border-b border-gray-100">
    <div class="flex justify-between items-center px-4 lg:px-8 py-4">
        <div class="flex items-center gap-3">
            {{-- Mobile toggle --}}
            <button id="open-sidebar" class="lg:hidden p-2 text-gray-500 hover:bg-gray-100 rounded-xl">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path></svg>
            </button>
            <div>
                <h1 class="text-lg font-bold text-gray-900">@yield('page-title', 'Dashboard')</h1>
                <p class="text-xs text-gray-500 mt-0.5">@yield('page-desc', '')</p>
            </div>
        </div>

        <div class="flex items-center gap-4">
            <div class="hidden sm:flex items-center gap-2 text-sm text-gray-500 bg-gray-50 px-4 py-2 rounded-xl">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>
                {{ now()->translatedFormat('d M Y') }}
            </div>
        </div>
    </div>
</header>