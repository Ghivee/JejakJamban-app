<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class DemoDataSeeder extends Seeder
{
    public function run(): void
    {
        if (app()->environment('production')) {
            throw new \RuntimeException('Data demo sintetis tidak boleh di-seed ke production.');
        }

        $demoPassword = env('JEJAKJAMBAN_DEMO_PASSWORD');
        if (! is_string($demoPassword) || strlen($demoPassword) < 12) {
            throw new \RuntimeException(
                'Atur JEJAKJAMBAN_DEMO_PASSWORD (minimal 12 karakter) untuk membuat akun demo lokal.',
            );
        }

        $user = User::updateOrCreate(
            ['email' => 'demo@jejakjamban.local'],
            [
                'name' => 'DemoJejak',
                'alias' => 'DemoJejak',
                'age' => 21,
                'health_data_consent_at' => now(),
                'password' => $demoPassword,
            ],
        );

        foreach ([3, 4, 5] as $index => $bristolType) {
            $loggedAt = now()->subDays($index);

            $user->bowelLogs()->updateOrCreate(
                ['client_id' => sprintf('00000000-0000-4000-8000-%012d', $index + 1)],
                [
                    'logged_at' => $loggedAt,
                    'bristol_type' => $bristolType,
                    'volume' => 'normal',
                    'duration_min' => 5 + $index,
                    'color' => 'brown',
                    'sensations' => ['tuntas'],
                    'mood' => 3,
                    'triggers' => [],
                    'note' => null,
                ],
            );
        }
    }
}
