<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('cash_advance_requests', function (Blueprint $table) {
            $table->unsignedInteger('outstanding_amount')->default(0)->after('amount');
            $table->unsignedInteger('installment_count')->default(1)->after('repayment_method');
            $table->unsignedInteger('installment_paid')->default(0)->after('installment_count');
            $table->timestamp('disbursed_at')->nullable()->after('reviewed_at');
            $table->timestamp('paid_at')->nullable()->after('disbursed_at');
        });
    }

    public function down(): void
    {
        Schema::table('cash_advance_requests', function (Blueprint $table) {
            $table->dropColumn([
                'outstanding_amount',
                'installment_count',
                'installment_paid',
                'disbursed_at',
                'paid_at',
            ]);
        });
    }
};
