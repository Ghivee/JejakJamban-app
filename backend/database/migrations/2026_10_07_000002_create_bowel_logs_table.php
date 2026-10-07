<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('bowel_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->uuid('client_id')->nullable();
            $table->timestamp('logged_at')->index();
            $table->unsignedTinyInteger('bristol_type');
            $table->string('volume', 12)->nullable();
            $table->unsignedSmallInteger('duration_min')->nullable();
            $table->string('color', 16)->nullable();
            $table->json('sensations')->nullable();
            $table->unsignedTinyInteger('mood')->nullable();
            $table->json('triggers')->nullable();
            $table->string('note', 280)->nullable();
            $table->unsignedSmallInteger('xp_awarded')->default(0);
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['user_id', 'client_id']);
            $table->index(['user_id', 'logged_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bowel_logs');
    }
};
