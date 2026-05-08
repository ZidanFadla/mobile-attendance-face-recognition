<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('attendances', function (Blueprint $table) {
            $table->string('status')->nullable();  // tepat_waktu / telat / pulang_awal / normal / lembur
            $table->boolean('is_lembur')->default(false);
            $table->integer('lembur_fee')->default(0); // nominal lembur dalam rupiah
        });
    }

    public function down(): void
    {
        Schema::table('attendances', function (Blueprint $table) {
            $table->dropColumn(['status', 'is_lembur', 'lembur_fee']);
        });
    }
};
