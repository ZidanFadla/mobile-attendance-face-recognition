<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('attendances', function (Blueprint $table) {
            $table->index('timestamp', 'attendances_timestamp_index');
            $table->index(['type', 'timestamp'], 'attendances_type_timestamp_index');
            $table->index(['status', 'timestamp'], 'attendances_status_timestamp_index');
            $table->index(['is_lembur', 'timestamp'], 'attendances_is_lembur_timestamp_index');
            $table->index(['employee_id', 'timestamp'], 'attendances_employee_timestamp_index');
        });

        Schema::table('messages', function (Blueprint $table) {
            $table->index('created_at', 'messages_created_at_index');
            $table->index(['is_read', 'created_at'], 'messages_is_read_created_at_index');
        });

        Schema::table('employees', function (Blueprint $table) {
            $table->index('name', 'employees_name_index');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('employees', function (Blueprint $table) {
            $table->dropIndex('employees_name_index');
        });

        Schema::table('messages', function (Blueprint $table) {
            $table->dropIndex('messages_is_read_created_at_index');
            $table->dropIndex('messages_created_at_index');
        });

        Schema::table('attendances', function (Blueprint $table) {
            $table->dropIndex('attendances_employee_timestamp_index');
            $table->dropIndex('attendances_is_lembur_timestamp_index');
            $table->dropIndex('attendances_status_timestamp_index');
            $table->dropIndex('attendances_type_timestamp_index');
            $table->dropIndex('attendances_timestamp_index');
        });
    }
};
