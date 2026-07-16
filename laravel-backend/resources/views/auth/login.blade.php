<x-guest-layout>
    <div class="clay-panel p-7 sm:p-8" x-data="{ loading: false }">
        <div class="mb-8 text-center">
            <a href="/" class="mx-auto mb-5 flex h-16 w-16 items-center justify-center rounded-[1.4rem] bg-gradient-to-br from-[#4F8EF7] to-[#7C5CFC] text-white shadow-lg shadow-blue-500/20">
                <svg class="h-8 w-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12.75 11.25 15 15 9.75M8.25 21h7.5A2.25 2.25 0 0 0 18 18.75V5.25A2.25 2.25 0 0 0 15.75 3h-7.5A2.25 2.25 0 0 0 6 5.25v13.5A2.25 2.25 0 0 0 8.25 21Z"/></svg>
            </a>
            <h1 class="text-3xl font-black tracking-tight text-slate-900">Selamat datang kembali</h1>
            <p class="mt-2 text-sm font-medium leading-6 text-slate-500">Masuk ke dashboard admin Absensi OB.</p>
        </div>

        <x-auth-session-status class="mb-5 rounded-2xl bg-blue-50 px-4 py-3 text-sm font-semibold text-blue-700" :status="session('status')" />

        <form method="POST" action="{{ route('login') }}" class="space-y-5" @submit="loading = true">
            @csrf

            <div class="group relative">
                <x-text-input id="email" class="peer block w-full !pt-6" type="email" name="email" :value="old('email')" required autofocus autocomplete="username" placeholder=" " />
                <label for="email" class="pointer-events-none absolute left-4 top-2 text-xs font-extrabold text-slate-500 transition-all peer-placeholder-shown:top-3.5 peer-placeholder-shown:text-sm peer-focus:top-2 peer-focus:text-xs peer-focus:text-[#4F8EF7]">Email</label>
                <x-input-error :messages="$errors->get('email')" class="mt-2" />
            </div>

            <div class="group relative">
                <x-text-input id="password" class="peer block w-full !pt-6" type="password" name="password" required autocomplete="current-password" placeholder=" " />
                <label for="password" class="pointer-events-none absolute left-4 top-2 text-xs font-extrabold text-slate-500 transition-all peer-placeholder-shown:top-3.5 peer-placeholder-shown:text-sm peer-focus:top-2 peer-focus:text-xs peer-focus:text-[#4F8EF7]">Password</label>
                <x-input-error :messages="$errors->get('password')" class="mt-2" />
            </div>

            <div class="flex items-center justify-between gap-4">
                <label for="remember_me" class="inline-flex cursor-pointer items-center gap-3">
                    <input id="remember_me" type="checkbox" class="peer sr-only" name="remember">
                    <span class="relative h-7 w-12 rounded-full bg-slate-200 transition peer-checked:bg-[#4F8EF7] after:absolute after:left-1 after:top-1 after:h-5 after:w-5 after:rounded-full after:bg-white after:shadow-sm after:transition peer-checked:after:translate-x-5"></span>
                    <span class="text-sm font-bold text-slate-600">Remember me</span>
                </label>

                @if (Route::has('password.request'))
                    <a class="text-sm font-bold text-[#4F8EF7] transition hover:text-[#7C5CFC]" href="{{ route('password.request') }}">
                        Lupa password?
                    </a>
                @endif
            </div>

            <button type="submit" class="btn-primary w-full !py-3.5" :disabled="loading" :class="loading ? 'opacity-80 cursor-wait' : ''">
                <span x-show="!loading">Masuk Dashboard</span>
                <span x-show="loading" class="inline-flex items-center gap-2"><span class="spinner"></span> Memproses...</span>
            </button>
        </form>
    </div>
</x-guest-layout>
