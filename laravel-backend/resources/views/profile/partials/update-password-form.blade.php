<form method="post" action="{{ route('password.update') }}" class="space-y-6">
    @csrf
    @method('put')

    <div class="grid grid-cols-1 gap-6">
        <div>
            <label for="current_password" class="block text-sm font-medium text-gray-700 mb-2">
                Password Saat Ini <span class="text-red-500">*</span>
            </label>
            <input type="password" 
                   id="current_password" 
                   name="current_password" 
                   required
                   autocomplete="current-password"
                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-admin-primary focus:border-transparent @error('current_password', 'updatePassword') border-red-500 @enderror"
                   placeholder="Masukkan password saat ini">
            @error('current_password', 'updatePassword')
                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
            @enderror
        </div>

        <div>
            <label for="password" class="block text-sm font-medium text-gray-700 mb-2">
                Password Baru <span class="text-red-500">*</span>
            </label>
            <input type="password" 
                   id="password" 
                   name="password" 
                   required
                   autocomplete="new-password"
                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-admin-primary focus:border-transparent @error('password', 'updatePassword') border-red-500 @enderror"
                   placeholder="Masukkan password baru (minimal 8 karakter)">
            @error('password', 'updatePassword')
                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
            @enderror
        </div>

        <div>
            <label for="password_confirmation" class="block text-sm font-medium text-gray-700 mb-2">
                Konfirmasi Password Baru <span class="text-red-500">*</span>
            </label>
            <input type="password" 
                   id="password_confirmation" 
                   name="password_confirmation" 
                   required
                   autocomplete="new-password"
                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-admin-primary focus:border-transparent @error('password_confirmation', 'updatePassword') border-red-500 @enderror"
                   placeholder="Ulangi password baru">
            @error('password_confirmation', 'updatePassword')
                <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
            @enderror
        </div>
    </div>

    <div class="flex items-center justify-between pt-6 border-t border-gray-200">
        <div class="text-sm text-gray-600">
            <span class="text-red-500">*</span> Field wajib diisi
        </div>

        <div class="flex items-center space-x-4">
            @if (session('status') === 'password-updated')
                <p class="text-sm text-green-600 font-medium">
                    ✓ Password berhasil diupdate
                </p>
            @endif

            <x-button variant="primary" type="submit">
                <x-slot name="icon">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path>
                    </svg>
                </x-slot>
                Update Password
            </x-button>
        </div>
    </div>
</form>
