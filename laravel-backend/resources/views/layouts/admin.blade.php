<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'Admin') - Absensi OB</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="min-h-screen antialiased" x-data="adminShell()">
    <div class="pointer-events-none fixed inset-0 -z-10 overflow-hidden">
        <div class="absolute left-[-10rem] top-[-12rem] h-96 w-96 rounded-full bg-blue-200/35 blur-3xl"></div>
        <div class="absolute right-[-12rem] top-1/3 h-[28rem] w-[28rem] rounded-full bg-violet-200/30 blur-3xl"></div>
    </div>

    <div class="min-h-screen lg:flex">
        @include('layouts.partials.sidebar')

        <div class="min-w-0 flex-1 lg:pl-80">
            @include('layouts.partials.header')

            <main class="px-4 py-6 sm:px-6 lg:px-10 lg:py-8">
                <div class="page-shell space-y-6">
                    @if(session('success'))
                        <div class="glass-panel flex items-center gap-3 rounded-3xl px-5 py-4 text-sm font-bold text-emerald-800 animate-fade-in-up" id="flash-msg">
                            <span class="icon-tile !h-9 !w-9 text-emerald-600">
                                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 6 9 17l-5-5"/></svg>
                            </span>
                            <span class="font-semibold">{{ session('success') }}</span>
                        </div>
                    @endif

                    @if(session('error'))
                        <div class="glass-panel flex items-center gap-3 rounded-3xl px-5 py-4 text-sm text-red-800 animate-fade-in-up">
                            <span class="icon-tile !h-9 !w-9 text-red-600">
                                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m18 6-12 12M6 6l12 12"/></svg>
                            </span>
                            <span class="font-semibold">{{ session('error') }}</span>
                        </div>
                    @endif

                    @if($errors->any())
                        <div class="glass-panel rounded-3xl px-5 py-4 text-sm text-red-800 animate-fade-in-up">
                            <p class="mb-2 font-extrabold">Periksa kembali input berikut:</p>
                            <ul class="list-inside list-disc space-y-1">
                                @foreach($errors->all() as $error)
                                    <li>{{ $error }}</li>
                                @endforeach
                            </ul>
                        </div>
                    @endif

                    @yield('content')
                </div>
            </main>
        </div>
    </div>

    <script>
        setTimeout(() => {
            const el = document.getElementById('flash-msg');
            if (el) { el.style.transition = 'opacity 0.5s, transform 0.5s'; el.style.opacity = '0'; el.style.transform = 'translateY(-8px)'; setTimeout(() => el.remove(), 500); }
        }, 4000);
    </script>
    @stack('scripts')
</body>
</html>
