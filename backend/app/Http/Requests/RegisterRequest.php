<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $rules = [
            'alias' => ['required', 'string', 'alpha_dash:ascii', 'min:3', 'max:20', Rule::unique('users', 'alias')],
            'email' => ['required', 'string', 'email', 'max:255', Rule::unique('users', 'email')],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'age' => ['required', 'integer', 'min:13', 'max:120'],
            'health_data_consent' => ['accepted'],
        ];

        if ($this->integer('age') >= 13 && $this->integer('age') <= 16) {
            $rules['parental_consent'] = ['required', 'accepted'];
        }

        return $rules;
    }
}
