<div class="grid grid-cols-3 gap-4 mb-6">
    <div class="bg-emerald-50 rounded-2xl p-5 text-center">
        <p class="text-2xl font-extrabold text-emerald-700">{{ $totalHadir }}</p>
        <p class="text-xs text-emerald-600 mt-1 font-medium">Total Kehadiran</p>
    </div>
    <div class="bg-red-50 rounded-2xl p-5 text-center">
        <p class="text-2xl font-extrabold text-red-600">{{ $totalTerlat }}</p>
        <p class="text-xs text-red-500 mt-1 font-medium">Total Terlambat</p>
    </div>
    <div class="bg-purple-50 rounded-2xl p-5 text-center">
        <p class="text-2xl font-extrabold text-purple-600">{{ $totalLembur }}</p>
        <p class="text-xs text-purple-500 mt-1 font-medium">Total Lembur</p>
    </div>
</div>

<table class="w-full text-sm">
    <thead><tr class="bg-slate-50/80">
        <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase">Nama</th>
        <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase">Jabatan</th>
        <th class="px-4 py-3 text-center text-xs font-semibold text-slate-500 uppercase">Hadir</th>
        <th class="px-4 py-3 text-center text-xs font-semibold text-slate-500 uppercase">Telat</th>
        <th class="px-4 py-3 text-center text-xs font-semibold text-slate-500 uppercase">Lembur</th>
    </tr></thead>
    <tbody class="divide-y divide-slate-100/80">
        @forelse($employees as $emp)
            <tr class="hover:bg-gray-50/50">
                <td class="px-4 py-3 font-medium text-slate-900">{{ $emp->name }}</td>
                <td class="px-4 py-3 text-slate-500 text-xs">{{ $emp->jabatan ?? '-' }}</td>
                <td class="px-4 py-3 text-center"><span class="text-emerald-700 font-bold">{{ $emp->hadir_count }}</span></td>
                <td class="px-4 py-3 text-center"><span class="{{ $emp->telat_count > 0 ? 'text-red-600 font-bold' : 'text-gray-300' }}">{{ $emp->telat_count }}</span></td>
                <td class="px-4 py-3 text-center"><span class="{{ $emp->lembur_count > 0 ? 'text-purple-600 font-bold' : 'text-gray-300' }}">{{ $emp->lembur_count }}</span></td>
            </tr>
        @empty
            <tr><td colspan="5" class="px-4 py-8 text-center text-slate-400 text-sm">Tidak ada data</td></tr>
        @endforelse
    </tbody>
</table>

@if(method_exists($employees, 'links') && $employees->hasPages())
    <div class="mt-4">{{ $employees->links() }}</div>
@endif