<?php

namespace App\Exports\Reports;

class DailyReportExport extends BaseReportExport
{
    protected function numericColumns(): array
    {
        return ['A'];
    }

    protected function currencyColumns(): array
    {
        return ['I'];
    }
}
