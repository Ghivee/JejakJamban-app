<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BowelLogResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'client_id' => $this->client_id,
            'logged_at' => $this->logged_at->toIso8601String(),
            'bristol_type' => $this->bristol_type,
            'volume' => $this->volume,
            'duration_min' => $this->duration_min,
            'color' => $this->color,
            'sensations' => $this->sensations ?? [],
            'mood' => $this->mood,
            'triggers' => $this->triggers ?? [],
            'note' => $this->note,
            'xp_awarded' => $this->xp_awarded,
            'sync_status' => 'synced',
            'updated_at' => $this->updated_at->toIso8601String(),
        ];
    }
}
