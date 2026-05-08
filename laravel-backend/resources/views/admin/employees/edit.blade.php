@extends('layouts.admin')
@section('title', 'Edit Karyawan')
@section('page-title', 'Edit Karyawan')
@section('page-desc', $employee->name)

@section('content')
<div class="max-w-2xl">
    <div class="bg-white rounded-2xl border border-gray-100 shadow-sm p-8">
        <form method="POST" action="{{ route('admin.employees.update', $employee) }}">
            @csrf @method('PUT')
            <div class="space-y-5">
                <div>
                    <label for="name" class="block text-sm font-semibold text-gray-700 mb-1.5">Nama Lengkap</label>
                    <input type="text" name="name" id="name" value="{{ old('name', $employee->name) }}" required class="input-field">
                    @error('name') <p class="text-red-500 text-xs mt-1.5">{{ $message }}</p> @enderror
                </div>
                <div>
                    <label for="phone" class="block text-sm font-semibold text-gray-700 mb-1.5">Nomor Telepon</label>
                    <input type="text" name="phone" id="phone" value="{{ old('phone', $employee->phone) }}" required class="input-field">
                    @error('phone') <p class="text-red-500 text-xs mt-1.5">{{ $message }}</p> @enderror
                </div>
                <div>
                    <label for="jabatan" class="block text-sm font-semibold text-gray-700 mb-1.5">Jabatan</label>
                    <select name="jabatan" id="jabatan" required class="input-field">
                        @foreach(['OB' => 'Office Boy', 'Security' => 'Security', 'Cleaning Service' => 'Cleaning Service', 'Maintenance' => 'Maintenance'] as $val => $label)
                            <option value="{{ $val }}" {{ old('jabatan', $employee->jabatan) === $val ? 'selected' : '' }}>{{ $label }}</option>
                        @endforeach
                    </select>
                    @error('jabatan') <p class="text-red-500 text-xs mt-1.5">{{ $message }}</p> @enderror
                </div>
                <div>
                    <label for="username" class="block text-sm font-semibold text-gray-700 mb-1.5">Username</label>
                    <input type="text" name="username" id="username" value="{{ old('username', $employee->username) }}" required class="input-field">
                    @error('username') <p class="text-red-500 text-xs mt-1.5">{{ $message }}</p> @enderror
                </div>
                <div>
                    <label for="password" class="block text-sm font-semibold text-gray-700 mb-1.5">Password <span class="text-gray-400 font-normal">(kosongkan jika tidak diubah)</span></label>
                    <input type="password" name="password" id="password" class="input-field" placeholder="Minimal 6 karakter">
                    @error('password') <p class="text-red-500 text-xs mt-1.5">{{ $message }}</p> @enderror
                </div>
            </div>
            <div class="flex items-center justify-end gap-3 mt-8 pt-6 border-t border-gray-100">
                <a href="{{ route('admin.employees.index') }}" class="btn-secondary">Batal</a>
                <button type="submit" class="btn-primary">Update Karyawan</button>
            </div>
        </form>
    </div>
</div>
@endsection