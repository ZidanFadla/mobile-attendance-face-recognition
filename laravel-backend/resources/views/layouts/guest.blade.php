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
    <main class="min-h-screen overflow-hidden bg-[#F4F6F8] lg:grid lg:grid-cols-[1fr_1fr]">
        <section class="relative hidden min-h-screen items-center overflow-hidden px-12 text-slate-900 lg:flex xl:px-16">
            <div class="absolute inset-0 bg-[linear-gradient(135deg,#F4F6F8_0%,#FFFFFF_48%,#EEF4FF_100%)]"></div>
            <div class="absolute inset-y-0 right-0 w-px bg-gradient-to-b from-transparent via-slate-200 to-transparent"></div>
            <div class="absolute left-12 top-12 h-24 w-24 rounded-[2rem] border border-white/80 bg-white/45 shadow-clay backdrop-blur-xl xl:left-16"></div>
            <div class="absolute bottom-16 right-16 h-40 w-56 rotate-[-8deg] rounded-[2rem] border border-white/80 bg-white/40 shadow-clay backdrop-blur-xl"></div>
            <div class="absolute left-0 top-1/2 h-[34rem] w-5 -translate-y-1/2 rounded-r-full bg-gradient-to-b from-[#4F8EF7] to-[#7C5CFC] opacity-80"></div>
            <div class="absolute inset-0 opacity-[.22] [background-image:linear-gradient(rgba(15,23,42,.08)_1px,transparent_1px),linear-gradient(90deg,rgba(15,23,42,.08)_1px,transparent_1px)] [background-size:44px_44px]"></div>

            <div class="relative z-10 max-w-2xl">
                <div class="mb-10 flex h-20 w-20 items-center justify-center rounded-[1.75rem] bg-gradient-to-br from-[#4F8EF7] to-[#7C5CFC] text-white shadow-[12px_12px_30px_rgba(79,142,247,.20),-8px_-8px_20px_rgba(255,255,255,.9)] ring-1 ring-white/70">
                    <svg class="h-10 w-10" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12.75 11.25 15 15 9.75M8.25 21h7.5A2.25 2.25 0 0 0 18 18.75V5.25A2.25 2.25 0 0 0 15.75 3h-7.5A2.25 2.25 0 0 0 6 5.25v13.5A2.25 2.25 0 0 0 8.25 21Z"/></svg>
                </div>

                <div class="rounded-[2rem] bg-white/62 p-8 shadow-clay ring-1 ring-white/80 backdrop-blur-xl xl:p-10">
                    <div class="mb-7 h-1.5 w-24 rounded-full bg-gradient-to-r from-[#4F8EF7] to-[#7C5CFC]"></div>
                    <h1 class="max-w-xl text-4xl font-black leading-[1.05] tracking-tight text-slate-950 xl:text-4xl">
                        Dashboard Admin CV. PATDARA KUSUMA JAYA
                    </h1>
                    <h2 class="mt-6 max-w-xl text-2xl font-extrabold leading-snug tracking-tight text-slate-600 xl:text-3xl">
                        Karyawan Office Boy Penempatan Markas Besar Angkatan Darat
                    </h2>
                </div>
            </div>
        </section>

        <section class="flex min-h-screen items-center justify-center px-4 py-10 sm:px-6 lg:px-12">
            <div class="w-full max-w-md">
                {{ $slot }}
            </div>
        </section>
    </main>
</body>
</html>
