<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class BowelLogRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $required = $this->isMethod('POST') ? 'required' : 'sometimes';
        $editableDays = $this->isMethod('POST') ? 7 : 30;
        $earliest = now()->subDays($editableDays)->toDateTimeString();

        return [
            'client_id' => ['sometimes', 'nullable', 'uuid'],
            'logged_at' => ['sometimes', 'date', 'before_or_equal:now', "after_or_equal:$earliest"],
            'bristol_type' => [$required, 'integer', 'between:1,7'],
            'volume' => ['sometimes', 'nullable', 'in:sedikit,normal,banyak'],
            'duration_min' => ['sometimes', 'nullable', 'integer', 'between:0,120'],
            'color' => ['sometimes', 'nullable', 'in:normal,brown,red,black,pale,yellow,green,other'],
            'sensations' => ['sometimes', 'array', 'max:4'],
            'sensations.*' => ['string', 'in:tuntas,tidak_tuntas,nyeri,mengejan'],
            'mood' => ['sometimes', 'nullable', 'integer', 'between:1,5'],
            'triggers' => ['sometimes', 'array', 'max:20'],
            'triggers.*' => ['string', 'max:40'],
            'note' => ['sometimes', 'nullable', 'string', 'max:280'],
        ];
    }
}
