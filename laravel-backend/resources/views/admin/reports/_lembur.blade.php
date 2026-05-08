<form method="GET" class="flex items-center gap-3 mb-6">
    <input type="hidden" name="tab" value="lembur">
    <input type="month" name="month" value="{{ $month }}" class="input-field !w-auto">
    <button type="submit" class="btn-primary !py-2">Filter</button>
</form>

<table class="w-full text-sm">
    <thead><tr class="bg-gray-50/80">
        <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Nama</th>
        <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Jabatan</th>
        <th class="px-4 py-3 text-center text-xs font-semibold text-gray-500 uppercase">Total Hari</th>
        <th class="px-4 py-3 text-right text-xs font-semibold text-gray-500 uppercase">Total Fee</th>
    </tr></thead>
    <tbody class="divide-y divide-gray-50">
        @forelse($lemburData as $row)
            <tr class="hover:bg-gray-50/50">
                <td class="px-4 py-3 font-medium text-gray-900">{{ $row->name }}</td>
                <td class="px-4 py-3 text-gray-500 text-xs">{{ $row->jabatan ?? '-' }}</td>
                <td class="px-4 py-3 text-center"><span class="text-purple-700 font-bold">{{ $row->total_hari_lembur }} hari</span></td>
                <td class="px-4 py-3 text-right font-bold text-gray-900">Rp {{ number_format($row->total_fee, 0, ',', '.') }}</td>
            </tr>
        @empty
            <tr><td colspan="4" class="px-4 py-8 text-center text-gray-400 text-sm">Tidak ada data lembur</td></tr>
        @endforelse
    </tbody>
    @if($lemburData->count() > 0)
        <tfoot class="bg-gray-50/80 font-bold">
            <tr>
                <td colspan="2" class="px-4 py-3 text-gray-900">Total</td>
                <td class="px-4 py-3 text-center text-purple-700">{{ $lemburData->sum('total_hari_lembur') }} hari</td>
                <td class="px-4 py-3 text-right text-gray-900">Rp {{ number_format($lemburData->sum('total_fee'), 0, ',', '.') }}</td>
            </tr>
        </tfoot>
    @endif
</table>
