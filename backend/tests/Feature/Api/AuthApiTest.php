<?php

namespace Tests\Feature\Api;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_registration_requires_health_consent_and_returns_a_token(): void
    {
        $this->postJson('/api/register', [
            'alias' => 'RinaSehat',
            'email' => 'rina@example.test',
            'password' => 'secret-password',
            'password_confirmation' => 'secret-password',
            'age' => 22,
            'health_data_consent' => true,
        ])->assertCreated()
            ->assertJsonPath('status', 'registered')
            ->assertJsonStructure(['token', 'data' => ['id', 'alias', 'email', 'age']]);
    }

    public function test_registration_blocks_children_under_thirteen(): void
    {
        $this->postJson('/api/register', [
            'alias' => 'AnakSehat',
            'email' => 'anak@example.test',
            'password' => 'secret-password',
            'password_confirmation' => 'secret-password',
            'age' => 12,
            'health_data_consent' => true,
        ])->assertUnprocessable()
            ->assertJsonValidationErrors('age');
    }

    public function test_login_returns_422_for_invalid_credentials(): void
    {
        $this->postJson('/api/login', [
            'email' => 'missing@example.test',
            'password' => 'incorrect',
        ])->assertUnprocessable()
            ->assertJsonValidationErrors('email');
    }
}
