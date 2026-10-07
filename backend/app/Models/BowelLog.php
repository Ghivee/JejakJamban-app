<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class BowelLog extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'client_id',
        'logged_at',
        'bristol_type',
        'volume',
        'duration_min',
        'color',
        'sensations',
        'mood',
        'triggers',
        'note',
    ];

    protected function casts(): array
    {
        return [
            'logged_at' => 'datetime',
            'bristol_type' => 'integer',
            'duration_min' => 'integer',
            'sensations' => 'array',
            'mood' => 'integer',
            'triggers' => 'array',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
