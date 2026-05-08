@extends('layouts.admin')

@section('title', 'Profile')

@section('content')
<div class="max-w-4xl mx-auto space-y-6">
    <!-- Profile Information -->
    <x-card title="Informasi Profile" subtitle="Update informasi profil dan alamat email Anda">
        <x-slot name="icon">
            <svg class="w-5 h-5 text-admin-primary" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd"></path>
            </svg>
        </x-slot>

        @include('profile.partials.update-profile-information-form')
    </x-card>

    <!-- Update Password -->
    <x-card title="Update Password" subtitle="Pastikan akun Anda menggunakan password yang panjang dan acak untuk tetap aman">
        <x-slot name="icon">
            <svg class="w-5 h-5 text-admin-primary" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M18 8a6 6 0 01-7.743 5.743L10 14l-1 1-1 1H6v2H2v-4l4.257-4.257A6 6 0 1118 8zm-6-4a1 1 0 100 2 2 2 0 012 2 1 1 0 102 0 4 4 0 00-4-4z" clip-rule="evenodd"></path>
            </svg>
        </x-slot>

        @include('profile.partials.update-password-form')
    </x-card>

    <!-- Delete Account -->
    <x-card title="Hapus Akun" subtitle="Setelah akun Anda dihapus, semua sumber daya dan data akan dihapus secara permanen" class="border-red-200">
        <x-slot name="icon">
            <svg class="w-5 h-5 text-red-600" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M9 2a1 1 0 000 2h2a1 1 0 100-2H9z" clip-rule="evenodd"></path>
                <path fill-rule="evenodd" d="M10 5a1 1 0 011 1v3l1.293-1.293a1 1 0 011.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 011.414-1.414L9 9V6a1 1 0 011-1z" clip-rule="evenodd"></path>
                <path d="M3 5a2 2 0 012-2h1a1 1 0 010 2H5v7h2l1 2h4l1-2h2V5h-1a1 1 0 110-2h1a2 2 0 012 2v10a2 2 0 01-2 2H5a2 2 0 01-2-2V5z"></path>
            </svg>
        </x-slot>

        @include('profile.partials.delete-user-form')
    </x-card>
</div>
@endsection
