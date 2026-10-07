<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('alias', 20)->nullable()->unique();
            $table->unsignedTinyInteger('age')->nullable();
            $table->timestamp('health_data_consent_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropUnique(['alias']);
            $table->dropColumn(['alias', 'age', 'health_data_consent_at']);
        });
    }
};
