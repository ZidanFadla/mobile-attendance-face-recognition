<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('leave_requests', function (Blueprint $table) {
            $table->string('attachment_path')->nullable()->after('handover_note');
            $table->string('attachment_name')->nullable()->after('attachment_path');
        });

        Schema::table('cash_advance_requests', function (Blueprint $table) {
            $table->string('attachment_path')->nullable()->after('account_number');
            $table->string('attachment_name')->nullable()->after('attachment_path');
        });
    }

    public function down(): void
    {
        Schema::table('leave_requests', function (Blueprint $table) {
            $table->dropColumn(['attachment_path', 'attachment_name']);
        });

        Schema::table('cash_advance_requests', function (Blueprint $table) {
            $table->dropColumn(['attachment_path', 'attachment_name']);
        });
    }
};
