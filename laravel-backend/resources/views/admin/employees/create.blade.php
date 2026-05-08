@extends('layouts.admin')
@section('title', 'Tambah Karyawan')
@section('page-title', 'Tambah Karyawan')
@section('page-desc', 'Daftarkan karyawan outsourcing baru')

@section('content')
<div class="max-w-2xl">
    <div class="bg-white rounded-2xl border border-gray-100 shadow-sm p-8">
        <form method="POST" action="{{ route('admin.employees.store') }}">
            @csrf
            <div class="space-y-5">
                <div>
                    <label for="name" class="block text-sm font-semibold text-gray-700 mb-1.5">Nama Lengkap</label>
                    <input type="text" name="name" id="name" value="{{ old('name') }}" required class="input-field" placeholder="Masukkan nama lengkap">
                    @error('name') <p class="text-red-500 text-xs mt-1.5">{{ $message }}</p> @enderror
                </div>
                <div>
                    <label for="phone" class="block text-sm font-semibold text-gray-700 mb-1.5">Nomor Telepon</label>
                    <input type="text" name="phone" id="phone" value="{{ old('phone') }}" required class="input-field" placeholder="08xxxxxxxxxx">
                    @error('phone') <p class="text-red-500 text-xs mt-1.5">{{ $message }}</p> @enderror
                </div>
                <div>
                    <label for="jabatan" class="block text-sm font-semibold text-gray-700 mb-1.5">Jabatan</label>
                    <select name="jabatan" id="jabatan" required class="input-field">
                        <option value="">— Pilih Jabatan —</option>
                        @foreach(['OB' => 'Office Boy', 'Security' => 'Security', 'Cleaning Service' => 'Cleaning Service', 'Maintenance' => 'Maintenance'] as $val => $label)
                            <option value="{{ $val }}" {{ old('jabatan') === $val ? 'selected' : '' }}>{{ $label }}</option>
                        @endforeach
                    </select>
                    @error('jabatan') <p class="text-red-500 text-xs mt-1.5">{{ $message }}</p> @enderror
                </div>
                <div>
                    <label for="username" class="block text-sm font-semibold text-gray-700 mb-1.5">Username</label>
                    <input type="text" name="username" id="username" value="{{ old('username') }}" required class="input-field" placeholder="Username untuk login di mobile app">
                    @error('username') <p class="text-red-500 text-xs mt-1.5">{{ $message }}</p> @enderror
                </div>
                <div>
                    <label for="password" class="block text-sm font-semibold text-gray-700 mb-1.5">Password</label>
                    <input type="password" name="password" id="password" required class="input-field" placeholder="Minimal 6 karakter">
                    @error('password') <p class="text-red-500 text-xs mt-1.5">{{ $message }}</p> @enderror
                </div>
            </div>
            <div class="flex items-center justify-end gap-3 mt-8 pt-6 border-t border-gray-100">
                <a href="{{ route('admin.employees.index') }}" class="btn-secondary">Batal</a>
                <button type="submit" class="btn-primary">Simpan Karyawan</button>
            </div>
        </form>
    </div>
</div>
@endsection