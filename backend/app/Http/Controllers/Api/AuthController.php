<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\RegisterRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(RegisterRequest $request): JsonResponse
    {
        $user = User::create([
            'name' => $request->string('alias')->toString(),
            'alias' => $request->string('alias')->toString(),
            'email' => $request->string('email')->lower()->toString(),
            'password' => $request->string('password')->toString(),
            'age' => $request->integer('age'),
            'health_data_consent_at' => now(),
        ]);

        return $this->tokenResponse($user, 'registered', 201);
    }

    public function login(Request $request): JsonResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::query()->where('email', strtolower($credentials['email']))->first();

        if ($user === null || ! Hash::check($credentials['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Email atau kata sandi tidak cocok.'],
            ]);
        }

        return $this->tokenResponse($user, 'authenticated');
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(['message' => 'Sesi berhasil diakhiri.']);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'data' => [
                'id' => $user->id,
                'alias' => $user->alias ?? $user->name,
                'email' => $user->email,
                'age' => $user->age,
            ],
        ]);
    }

    private function tokenResponse(User $user, string $status, int $statusCode = 200): JsonResponse
    {
        return response()->json([
            'status' => $status,
            'token' => $user->createToken('jejakjamban-mobile')->plainTextToken,
            'data' => [
                'id' => $user->id,
                'alias' => $user->alias,
                'email' => $user->email,
                'age' => $user->age,
            ],
        ], $statusCode);
    }
}
