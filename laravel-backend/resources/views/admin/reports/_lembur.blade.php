<table class="w-full text-sm">
    <thead><tr class="bg-slate-50/80">
        <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase">Nama</th>
        <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase">Jabatan</th>
        <th class="px-4 py-3 text-center text-xs font-semibold text-slate-500 uppercase">Total Hari</th>
        <th class="px-4 py-3 text-right text-xs font-semibold text-slate-500 uppercase">Total Fee</th>
    </tr></thead>
    <tbody class="divide-y divide-slate-100/80">
        @forelse($lemburData as $row)
            <tr class="hover:bg-gray-50/50">
                <td class="px-4 py-3 font-medium text-slate-900">{{ $row->name }}</td>
                <td class="px-4 py-3 text-slate-500 text-xs">{{ $row->jabatan ?? '-' }}</td>
                <td class="px-4 py-3 text-center"><span class="text-purple-700 font-bold">{{ $row->total_hari_lembur }} hari</span></td>
                <td class="px-4 py-3 text-right font-bold text-slate-900">Rp {{ number_format($row->total_fee, 0, ',', '.') }}</td>
            </tr>
        @empty
            <tr><td colspan="4" class="px-4 py-8 text-center text-slate-400 text-sm">Tidak ada data lembur</td></tr>
        @endforelse
    </tbody>
    @if(($totalHariLembur ?? $lemburData->count()) > 0)
        <tfoot class="bg-slate-50/80 font-bold">
            <tr>
                <td colspan="2" class="px-4 py-3 text-slate-900">Total</td>
                <td class="px-4 py-3 text-center text-purple-700">{{ $totalHariLembur ?? $lemburData->sum('total_hari_lembur') }} hari</td>
                <td class="px-4 py-3 text-right text-slate-900">Rp {{ number_format($totalFeeLembur ?? $lemburData->sum('total_fee'), 0, ',', '.') }}</td>
            </tr>
        </tfoot>
    @endif
</table>

@if(method_exists($lemburData, 'links') && $lemburData->hasPages())
    <div class="mt-4">{{ $lemburData->links() }}</div>
@endif