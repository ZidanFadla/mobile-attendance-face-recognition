<?php

namespace App\Providers;

use App\Models\CashAdvanceRequest;
use App\Models\LeaveRequest;
use App\Models\Message;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\Facades\View;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        if (app()->environment('production')) {
            URL::forceScheme('https');
        }

        View::composer(['layouts.admin', 'layouts.partials.sidebar', 'layouts.partials.header'], function ($view) {
            $counts = Cache::store('file')->remember('admin_layout_counts', 30, function () {
                return [
                    'adminUnreadCount' => Message::where('is_read', false)->count(),
                    'adminPendingLeaveCount' => LeaveRequest::where('status', 'pending')->count(),
                    'adminPendingCashAdvanceCount' => CashAdvanceRequest::where('status', 'pending')->count(),
                ];
            });

            $counts['adminNotificationTotal'] = $counts['adminUnreadCount']
                + $counts['adminPendingLeaveCount']
                + $counts['adminPendingCashAdvanceCount'];

            $view->with($counts);
        });
    }
}
