<?php

namespace App\Exports\Reports;

class MonthlyReportExport extends BaseReportExport
{
    protected function numericColumns(): array
    {
        return ['A', 'D', 'E', 'F', 'G'];
    }
}
