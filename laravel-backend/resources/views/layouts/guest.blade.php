<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>{{ config('app.name', 'Absensi OB') }}</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="text-slate-900 antialiased">
    <main class="min-h-screen overflow-hidden lg:grid lg:grid-cols-[1.05fr_.95fr]">
        <section class="relative hidden min-h-screen flex-col justify-between overflow-hidden bg-slate-950 p-10 text-white lg:flex">
            <div class="absolute inset-0 bg-[radial-gradient(circle_at_20%_20%,rgba(79,142,247,.45),transparent_26rem),radial-gradient(circle_at_84%_22%,rgba(124,92,252,.38),transparent_24rem),linear-gradient(135deg,#0f172a,#111827_55%,#1e1b4b)]"></div>
            <div class="absolute inset-x-10 top-28 h-80 rounded-[3rem] border border-white/10 bg-white/5 backdrop-blur-2xl"></div>
            <div class="relative z-10 flex items-center gap-3">
                <div class="flex h-12 w-12 items-center justify-center rounded-3xl bg-white/12 shadow-2xl backdrop-blur">
                    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12.75 11.25 15 15 9.75M8.25 21h7.5A2.25 2.25 0 0 0 18 18.75V5.25A2.25 2.25 0 0 0 15.75 3h-7.5A2.25 2.25 0 0 0 6 5.25v13.5A2.25 2.25 0 0 0 8.25 21Z"/></svg>
                </div>
                <div>
                    <p class="text-lg font-black tracking-tight">Absensi OB</p>
                    <p class="text-xs font-semibold text-white/55">Admin Attendance Suite</p>
                </div>
            </div>

            <div class="relative z-10 max-w-xl">
                <span class="mb-5 inline-flex rounded-full border border-white/12 bg-white/10 px-4 py-2 text-xs font-bold text-blue-100 backdrop-blur">Modern attendance operations</span>
                <h1 class="text-5xl font-black leading-tight tracking-tight">Kelola presensi, pengajuan, dan komunikasi dalam satu dashboard.</h1>
                <p class="mt-6 max-w-lg text-base font-medium leading-8 text-slate-300">Antarmuka admin yang bersih membantu tim membaca data cepat, mengambil keputusan, dan menjaga proses operasional tetap rapi.</p>
                <div class="mt-8 grid max-w-lg grid-cols-3 gap-3">
                    <div class="rounded-3xl bg-white/10 p-4 backdrop-blur">
                        <p class="text-2xl font-black">Live</p>
                        <p class="mt-1 text-xs font-semibold text-white/55">Attendance</p>
                    </div>
                    <div class="rounded-3xl bg-white/10 p-4 backdrop-blur">
                        <p class="text-2xl font-black">Face</p>
                        <p class="mt-1 text-xs font-semibold text-white/55">Verification</p>
                    </div>
                    <div class="rounded-3xl bg-white/10 p-4 backdrop-blur">
                        <p class="text-2xl font-black">Admin</p>
                        <p class="mt-1 text-xs font-semibold text-white/55">Control</p>
                    </div>
                </div>
            </div>

            <p class="relative z-10 text-xs font-semibold text-white/45">Premium dashboard experience for {{ now()->year }}</p>
        </section>

        <section class="flex min-h-screen items-center justify-center px-4 py-10 sm:px-6 lg:px-12">
            <div class="w-full max-w-md">
                {{ $slot }}
            </div>
        </section>
    </main>
</body>
</html>
