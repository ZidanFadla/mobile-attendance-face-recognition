<form method="GET" class="flex items-center gap-3 mb-6">
    <input type="hidden" name="tab" value="tahunan">
    <select name="year" class="input-field !w-auto">
        @for($y = now()->year; $y >= now()->year - 3; $y--)
            <option value="{{ $y }}" {{ $year == $y ? 'selected' : '' }}>{{ $y }}</option>
        @endfor
    </select>
    <button type="submit" class="btn-primary !py-2">Filter</button>
</form>

<table class="w-full text-sm">
    <thead><tr class="bg-gray-50/80">
        <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Bulan</th>
        <th class="px-4 py-3 text-center text-xs font-semibold text-gray-500 uppercase">Hadir</th>
        <th class="px-4 py-3 text-center text-xs font-semibold text-gray-500 uppercase">Telat</th>
        <th class="px-4 py-3 text-center text-xs font-semibold text-gray-500 uppercase">Lembur</th>
    </tr></thead>
    <tbody class="divide-y divide-gray-50">
        @foreach($monthlyData as $m)
            <tr class="hover:bg-gray-50/50">
                <td class="px-4 py-3 font-medium text-gray-900">{{ $m['bulan'] }}</td>
                <td class="px-4 py-3 text-center"><span class="text-emerald-700 font-bold">{{ $m['hadir'] }}</span></td>
                <td class="px-4 py-3 text-center"><span class="{{ $m['telat'] > 0 ? 'text-red-600 font-bold' : 'text-gray-300' }}">{{ $m['telat'] }}</span></td>
                <td class="px-4 py-3 text-center"><span class="{{ $m['lembur'] > 0 ? 'text-purple-600 font-bold' : 'text-gray-300' }}">{{ $m['lembur'] }}</span></td>
            </tr>
        @endforeach
    </tbody>
    <tfoot class="bg-gray-50/80 font-bold">
        <tr>
            <td class="px-4 py-3 text-gray-900">Total</td>
            <td class="px-4 py-3 text-center text-emerald-700">{{ collect($monthlyData)->sum('hadir') }}</td>
            <td class="px-4 py-3 text-center text-red-600">{{ collect($monthlyData)->sum('telat') }}</td>
            <td class="px-4 py-3 text-center text-purple-600">{{ collect($monthlyData)->sum('lembur') }}</td>
        </tr>
    </tfoot>
</table>
