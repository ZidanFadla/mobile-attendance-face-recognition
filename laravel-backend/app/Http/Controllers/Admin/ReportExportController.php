<?php

namespace App\Http\Controllers\Admin;

use App\Exports\Reports\DailyReportExport;
use App\Exports\Reports\MonthlyReportExport;
use App\Exports\Reports\YearlyReportExport;
use App\Http\Controllers\Controller;
use App\Services\Reports\AttendanceReportService;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Maatwebsite\Excel\Facades\Excel;

class ReportExportController extends Controller
{
    public function __construct(private AttendanceReportService $reports)
    {
    }

    public function exportExcel(Request $request)
    {
        $report = $this->reports->build($request);
        $this->ensureHasData($report);

        $export = match ($report['type']) {
            'monthly' => new MonthlyReportExport($report),
            'yearly' => new YearlyReportExport($report),
            default => new DailyReportExport($report),
        };

        return Excel::download($export, $this->reports->filename($report['type'], 'xlsx', $report));
    }

    public function exportPdf(Request $request)
    {
        $report = $this->reports->build($request);
        $this->ensureHasData($report);

        $orientation = $report['type'] === 'daily' ? 'landscape' : 'portrait';
        $pdfView = 'reports.pdf.' . $report['type'];
        $pdf = Pdf::loadView($pdfView, ['report' => $report])
            ->setPaper('a4', $orientation);

        return $pdf->download($this->reports->filename($report['type'], 'pdf', $report));
    }

    private function ensureHasData(array $report): void
    {
        if ($report['rows']->isEmpty()) {
            throw ValidationException::withMessages([
                'report' => 'Tidak ada data untuk periode dan filter yang dipilih.',
            ]);
        }
    }
}
