<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up()
    {
        Schema::table('messages', function (Blueprint $table) {
            $table->string('image_path')->nullable()->after('file_name');
            $table->string('image_name')->nullable()->after('image_path');
        });

        DB::statement("ALTER TABLE messages MODIFY COLUMN type ENUM('text', 'image', 'file', 'mixed')");
    }

    public function down()
    {
        Schema::table('messages', function (Blueprint $table) {
            $table->dropColumn(['image_path', 'image_name']);
        });

        DB::statement("ALTER TABLE messages MODIFY COLUMN type ENUM('text', 'image', 'file')");
    }
};
