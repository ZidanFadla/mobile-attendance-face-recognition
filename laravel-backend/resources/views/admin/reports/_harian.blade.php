<form method="GET" class="flex items-center gap-3 mb-6">
    <input type="hidden" name="tab" value="harian">
    <input type="date" name="date" value="{{ $date }}" class="input-field !w-auto">
    <button type="submit" class="btn-primary !py-2">Filter</button>
</form>

<div class="grid grid-cols-3 gap-4 mb-6">
    <div class="bg-emerald-50 rounded-2xl p-5 text-center">
        <p class="text-2xl font-extrabold text-emerald-700">{{ $totalMasuk }}</p>
        <p class="text-xs text-emerald-600 mt-1 font-medium">Hadir</p>
    </div>
    <div class="bg-red-50 rounded-2xl p-5 text-center">
        <p class="text-2xl font-extrabold text-red-600">{{ $totalTerlat }}</p>
        <p class="text-xs text-red-500 mt-1 font-medium">Terlambat</p>
    </div>
    <div class="bg-purple-50 rounded-2xl p-5 text-center">
        <p class="text-2xl font-extrabold text-purple-600">{{ $totalLembur }}</p>
        <p class="text-xs text-purple-500 mt-1 font-medium">Lembur</p>
    </div>
</div>

<table class="w-full text-sm">
    <thead><tr class="bg-gray-50/80">
        <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Nama</th>
        <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Tipe</th>
        <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Jam</th>
        <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Status</th>
    </tr></thead>
    <tbody class="divide-y divide-gray-50">
        @forelse($attendances as $att)
            <tr class="hover:bg-gray-50/50">
                <td class="px-4 py-3 font-medium text-gray-900">{{ $att->name }}</td>
                <td class="px-4 py-3"><span class="px-2 py-0.5 rounded-lg text-xs font-semibold {{ $att->type === 'Masuk' ? 'bg-emerald-100 text-emerald-700' : 'bg-blue-100 text-blue-700' }}">{{ $att->type }}</span></td>
                <td class="px-4 py-3 font-mono text-gray-600">{{ \Carbon\Carbon::parse($att->timestamp)->format('H:i') }}</td>
                <td class="px-4 py-3">
                    @if($att->status === 'tepat_waktu') <span class="text-emerald-600 text-xs font-semibold">Tepat Waktu</span>
                    @elseif($att->status === 'telat') <span class="text-red-600 text-xs font-semibold">Terlambat</span>
                    @else <span class="text-gray-400 text-xs">{{ $att->status ?? '-' }}</span>
                    @endif
                </td>
            </tr>
        @empty
            <tr><td colspan="4" class="px-4 py-8 text-center text-gray-400 text-sm">Tidak ada data</td></tr>
        @endforelse
    </tbody>
</table>
