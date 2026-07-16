<?php

namespace App\Services\Reports;

use App\Models\Attendance;
use App\Models\Employee;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class AttendanceReportService
{
    public function build(Request $request): array
    {
        $type = $this->normalizeType($request->get('report_type', $request->get('tab', 'daily')));

        return match ($type) {
            'monthly' => $this->monthly($request),
            'yearly' => $this->yearly($request),
            default => $this->daily($request),
        };
    }

    public function normalizeType(?string $type): string
    {
        return match ($type) {
            'harian', 'daily' => 'daily',
            'bulanan', 'monthly' => 'monthly',
            'tahunan', 'yearly' => 'yearly',
            default => 'daily',
        };
    }

    public function tabForType(string $type): string
    {
        return match ($this->normalizeType($type)) {
            'monthly' => 'bulanan',
            'yearly' => 'tahunan',
            default => 'harian',
        };
    }

    public function filename(string $type, string $format, array $report): string
    {
        $suffix = match ($type) {
            'monthly' => Carbon::parse($report['period_start'])->format('Y-m'),
            'yearly' => Carbon::parse($report['period_start'])->format('Y'),
            default => Carbon::parse($report['period_start'])->format('Y-m-d'),
        };

        $label = match ($type) {
            'monthly' => 'laporan-bulanan',
            'yearly' => 'laporan-tahunan',
            default => 'laporan-harian',
        };

        return $label . '-' . $suffix . '.' . $format;
    }

    private function daily(Request $request): array
    {
        $date = $request->get('date', today()->format('Y-m-d'));
        $period = $this->parseDate($date, 'date')->startOfDay();
        $periodEnd = $period->copy()->endOfDay();
        $employeeId = $request->integer('employee_id') ?: null;
        $status = $request->get('status');

        $query = Attendance::with('employee:id,name,jabatan')
            ->whereBetween('timestamp', [$period, $periodEnd])
            ->when($employeeId, fn ($q) => $q->where('employee_id', $employeeId))
            ->when($status && $status !== 'all', fn ($q) => $q->where('status', $status))
            ->orderBy('timestamp');

        $records = $query->get();
        $rows = $records->map(fn ($att, $index) => [
            'No' => $index + 1,
            'Nama' => $att->employee->name ?? $att->name ?? '-',
            'Jabatan' => $att->employee->jabatan ?? '-',
            'Tipe' => $att->type,
            'Tanggal' => Carbon::parse($att->timestamp)->format('d/m/Y'),
            'Jam' => Carbon::parse($att->timestamp)->format('H:i'),
            'Status' => $this->statusLabel($att->status),
            'Lembur' => $att->is_lembur ? 'Ya' : 'Tidak',
            'Fee Lembur' => (int) ($att->lembur_fee ?? 0),
            'Lokasi' => $att->location_name ?? '-',
        ])->values();

        return $this->payload('daily', $period, $periodEnd, $rows, [
            'date' => $period->format('Y-m-d'),
            'employee_id' => $employeeId,
            'status' => $status ?: 'all',
        ]);
    }

    private function monthly(Request $request): array
    {
        $month = $request->get('month', now()->format('Y-m'));
        $start = $this->parseMonth($month)->startOfMonth();
        $end = $start->copy()->endOfMonth();
        $employeeId = $request->integer('employee_id') ?: null;

        $employees = Employee::query()
            ->when($employeeId, fn ($q) => $q->where('id', $employeeId))
            ->withCount([
                'attendances as hadir_count' => fn ($q) => $q->where('type', 'Masuk')->whereBetween('timestamp', [$start, $end]),
                'attendances as telat_count' => fn ($q) => $q->where('type', 'Masuk')->where('status', 'telat')->whereBetween('timestamp', [$start, $end]),
                'attendances as lembur_count' => fn ($q) => $q->where('is_lembur', true)->whereBetween('timestamp', [$start, $end]),
                'attendances as pulang_count' => fn ($q) => $q->where('type', 'Pulang')->whereBetween('timestamp', [$start, $end]),
            ])
            ->orderBy('name')
            ->get();

        $rows = $employees->map(fn ($employee, $index) => [
            'No' => $index + 1,
            'Nama' => $employee->name,
            'Jabatan' => $employee->jabatan ?? '-',
            'Hadir' => (int) $employee->hadir_count,
            'Terlambat' => (int) $employee->telat_count,
            'Pulang' => (int) $employee->pulang_count,
            'Lembur' => (int) $employee->lembur_count,
        ])->values();

        return $this->payload('monthly', $start, $end, $rows, [
            'month' => $start->format('Y-m'),
            'employee_id' => $employeeId,
        ]);
    }

    private function yearly(Request $request): array
    {
        $year = (int) $request->get('year', now()->year);
        if ($year < 2000 || $year > ((int) now()->year + 1)) {
            throw ValidationException::withMessages(['year' => 'Tahun laporan tidak valid.']);
        }

        $start = Carbon::create($year, 1, 1)->startOfYear();
        $end = $start->copy()->endOfYear();

        $statsByMonth = Attendance::query()
            ->whereBetween('timestamp', [$start, $end])
            ->selectRaw(
                'EXTRACT(MONTH FROM "timestamp")::int as month_number,
                COUNT(DISTINCT CASE WHEN type = ? THEN employee_id END) as hadir,
                SUM(CASE WHEN type = ? AND status = ? THEN 1 ELSE 0 END) as telat,
                SUM(CASE WHEN is_lembur = true THEN 1 ELSE 0 END) as lembur',
                ['Masuk', 'Masuk', 'telat']
            )
            ->groupBy(DB::raw('EXTRACT(MONTH FROM "timestamp")'))
            ->get()
            ->keyBy('month_number');

        $rows = collect(range(1, 12))->map(function ($month, $index) use ($year, $statsByMonth) {
            $monthStart = Carbon::create($year, $month, 1)->startOfMonth();
            $stats = $statsByMonth->get($month);

            return [
                'No' => $index + 1,
                'Bulan' => $monthStart->translatedFormat('F'),
                'Hadir' => (int) ($stats->hadir ?? 0),
                'Terlambat' => (int) ($stats->telat ?? 0),
                'Lembur' => (int) ($stats->lembur ?? 0),
            ];
        });

        return $this->payload('yearly', $start, $end, $rows, ['year' => $year]);
    }

    public function overtime(Request $request): array
    {
        $month = $request->get('month', now()->format('Y-m'));
        $start = $this->parseMonth($month)->startOfMonth();
        $end = $start->copy()->endOfMonth();

        $rows = DB::table('attendances')
            ->join('employees', 'attendances.employee_id', '=', 'employees.id')
            ->select('employees.name', 'employees.jabatan', DB::raw('COUNT(*) as total_hari_lembur'), DB::raw('SUM(lembur_fee) as total_fee'))
            ->where('attendances.is_lembur', true)
            ->whereBetween('attendances.timestamp', [$start, $end])
            ->groupBy('employees.id', 'employees.name', 'employees.jabatan')
            ->orderByDesc('total_hari_lembur')
            ->get()
            ->map(fn ($row, $index) => [
                'No' => $index + 1,
                'Nama' => $row->name,
                'Jabatan' => $row->jabatan ?? '-',
                'Total Hari' => (int) $row->total_hari_lembur,
                'Total Fee' => (int) $row->total_fee,
            ]);

        return $this->payload('overtime', $start, $end, $rows, ['month' => $start->format('Y-m')]);
    }

    private function payload(string $type, Carbon $start, Carbon $end, Collection $rows, array $filters): array
    {
        $summary = $this->summary($type, $rows);

        return [
            'type' => $type,
            'title' => $this->title($type, $start),
            'period_label' => $this->periodLabel($type, $start, $end),
            'period_start' => $start,
            'period_end' => $end,
            'generated_at' => now(),
            'generated_by' => auth()->user()->name ?? 'Admin',
            'filters' => $this->filterLabels($filters),
            'rows' => $rows,
            'headings' => array_keys($rows->first() ?? $this->emptyRow($type)),
            'summary' => $summary,
            'app_name' => config('app.name', 'Absensi OB'),
        ];
    }

    private function summary(string $type, Collection $rows): array
    {
        return match ($type) {
            'monthly' => [
                'Total records' => $rows->count(),
                'Total hadir' => $rows->sum('Hadir'),
                'Total terlambat' => $rows->sum('Terlambat'),
                'Total lembur' => $rows->sum('Lembur'),
            ],
            'yearly' => [
                'Total records' => $rows->count(),
                'Total hadir' => $rows->sum('Hadir'),
                'Total terlambat' => $rows->sum('Terlambat'),
                'Total lembur' => $rows->sum('Lembur'),
            ],
            'overtime' => [
                'Total records' => $rows->count(),
                'Total hari lembur' => $rows->sum('Total Hari'),
                'Total fee lembur' => $rows->sum('Total Fee'),
            ],
            default => [
                'Total records' => $rows->count(),
                'Total masuk' => $rows->where('Tipe', 'Masuk')->count(),
                'Total pulang' => $rows->where('Tipe', 'Pulang')->count(),
                'Total terlambat' => $rows->where('Status', 'Terlambat')->count(),
                'Total lembur' => $rows->where('Lembur', 'Ya')->count(),
                'Total fee lembur' => $rows->sum('Fee Lembur'),
            ],
        };
    }

    private function title(string $type, Carbon $start): string
    {
        return match ($type) {
            'monthly' => 'Monthly Report - ' . $start->translatedFormat('F Y'),
            'yearly' => 'Yearly Report - ' . $start->format('Y'),
            'overtime' => 'Overtime Report - ' . $start->translatedFormat('F Y'),
            default => 'Daily Report - ' . $start->translatedFormat('d F Y'),
        };
    }

    private function periodLabel(string $type, Carbon $start, Carbon $end): string
    {
        return match ($type) {
            'monthly', 'overtime' => $start->translatedFormat('F Y'),
            'yearly' => $start->format('Y'),
            default => $start->translatedFormat('d F Y'),
        };
    }

    private function filterLabels(array $filters): array
    {
        $labels = [];
        if (!empty($filters['employee_id'])) {
            $labels['Karyawan'] = Employee::find($filters['employee_id'])?->name ?? 'Tidak ditemukan';
        }
        if (!empty($filters['status']) && $filters['status'] !== 'all') {
            $labels['Status'] = $this->statusLabel($filters['status']);
        }
        if (!empty($filters['date'])) $labels['Tanggal'] = $filters['date'];
        if (!empty($filters['month'])) $labels['Bulan'] = $filters['month'];
        if (!empty($filters['year'])) $labels['Tahun'] = $filters['year'];

        return $labels ?: ['Filter' => 'Semua data'];
    }

    private function emptyRow(string $type): array
    {
        return match ($type) {
            'monthly' => ['No' => null, 'Nama' => null, 'Jabatan' => null, 'Hadir' => null, 'Terlambat' => null, 'Pulang' => null, 'Lembur' => null],
            'yearly' => ['No' => null, 'Bulan' => null, 'Hadir' => null, 'Terlambat' => null, 'Lembur' => null],
            default => ['No' => null, 'Nama' => null, 'Jabatan' => null, 'Tipe' => null, 'Tanggal' => null, 'Jam' => null, 'Status' => null, 'Lembur' => null, 'Fee Lembur' => null, 'Lokasi' => null],
        };
    }

    private function parseDate(string $value, string $field): Carbon
    {
        try {
            return Carbon::parse($value);
        } catch (\Throwable) {
            throw ValidationException::withMessages([$field => 'Tanggal laporan tidak valid.']);
        }
    }

    private function parseMonth(string $value): Carbon
    {
        try {
            return Carbon::createFromFormat('Y-m', $value);
        } catch (\Throwable) {
            throw ValidationException::withMessages(['month' => 'Bulan laporan tidak valid.']);
        }
    }

    private function statusLabel(?string $status): string
    {
        return match ($status) {
            'tepat_waktu' => 'Tepat Waktu',
            'telat' => 'Terlambat',
            default => $status ? ucfirst(str_replace('_', ' ', $status)) : '-',
        };
    }
}
