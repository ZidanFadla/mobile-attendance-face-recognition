<?php

namespace App\Exports\Reports;

class YearlyReportExport extends BaseReportExport
{
    protected function numericColumns(): array
    {
        return ['A', 'C', 'D', 'E'];
    }
}
