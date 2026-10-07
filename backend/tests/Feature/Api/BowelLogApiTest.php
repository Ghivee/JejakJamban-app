<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BowelLogApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_guest_cannot_read_private_logs(): void
    {
        $this->getJson('/api/logs')->assertUnauthorized();
    }

    public function test_user_can_create_read_update_and_delete_a_log(): void
    {
        $user = User::factory()->create(['alias' => 'JejakUser']);
        $this->actingAs($user, 'sanctum');

        $created = $this->postJson('/api/logs', [
            'bristol_type' => 4,
            'volume' => 'normal',
            'duration_min' => 6,
            'color' => 'brown',
            'sensations' => ['tuntas'],
            'note' => 'Catatan demo',
        ])->assertCreated()
            ->assertJsonPath('data.bristol_type', 4)
            ->assertJsonPath('data.sync_status', 'synced');

        $id = $created->json('data.id');

        $this->getJson("/api/logs/$id")
            ->assertOk()
            ->assertJsonPath('data.note', 'Catatan demo');

        $this->putJson("/api/logs/$id", ['bristol_type' => 3])
            ->assertOk()
            ->assertJsonPath('data.bristol_type', 3);

        $this->deleteJson("/api/logs/$id")
            ->assertOk()
            ->assertJsonPath('message', 'Jejak berhasil dihapus.');

        $this->getJson("/api/logs/$id")->assertNotFound();
    }

    public function test_validation_rejects_invalid_bristol_type_and_long_note(): void
    {
        $this->actingAs(User::factory()->create(), 'sanctum');

        $this->postJson('/api/logs', [
            'bristol_type' => 8,
            'note' => str_repeat('a', 281),
        ])->assertUnprocessable()
            ->assertJsonValidationErrors(['bristol_type', 'note']);
    }

    public function test_repeating_a_client_id_does_not_create_duplicate_logs(): void
    {
        $this->actingAs(User::factory()->create(), 'sanctum');
        $payload = [
            'client_id' => 'f6b5a6dd-ef2e-4de0-86d5-fb6efc7a16db',
            'bristol_type' => 4,
        ];

        $first = $this->postJson('/api/logs', $payload)->assertCreated();
        $second = $this->postJson('/api/logs', $payload)->assertOk();

        $this->assertSame($first->json('data.id'), $second->json('data.id'));
        $this->assertDatabaseCount('bowel_logs', 1);
    }

    public function test_user_cannot_access_another_users_log(): void
    {
        $owner = User::factory()->create();
        $other = User::factory()->create();
        $log = $owner->bowelLogs()->create(['logged_at' => now(), 'bristol_type' => 4]);

        $this->actingAs($other, 'sanctum')
            ->getJson("/api/logs/$log->id")
            ->assertNotFound();
    }

    public function test_list_contains_only_the_authenticated_users_logs(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();
        $user->bowelLogs()->create(['logged_at' => now(), 'bristol_type' => 4]);
        $other->bowelLogs()->create(['logged_at' => now(), 'bristol_type' => 2]);

        $this->actingAs($user, 'sanctum')
            ->getJson('/api/logs')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.bristol_type', 4);
    }
}
