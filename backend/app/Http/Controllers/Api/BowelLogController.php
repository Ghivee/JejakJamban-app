<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\BowelLogRequest;
use App\Http\Resources\BowelLogResource;
use App\Models\BowelLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class BowelLogController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $logs = $request->user()
            ->bowelLogs()
            ->latest('logged_at')
            ->paginate(max(1, min($request->integer('per_page', 20), 100)));

        return BowelLogResource::collection($logs);
    }

    public function store(BowelLogRequest $request): JsonResponse
    {
        $attributes = [
            ...$request->validated(),
            'logged_at' => $request->validated('logged_at', now()),
        ];
        $clientId = $attributes['client_id'] ?? null;
        $log = $clientId === null
            ? $request->user()->bowelLogs()->create($attributes)
            : $request->user()->bowelLogs()->firstOrCreate(
                ['client_id' => $clientId],
                $attributes,
            );

        return (new BowelLogResource($log))
            ->response()
            ->setStatusCode($log->wasRecentlyCreated ? 201 : 200);
    }

    public function show(Request $request, int $log): BowelLogResource
    {
        return new BowelLogResource($this->ownedLog($request, $log));
    }

    public function update(BowelLogRequest $request, int $log): BowelLogResource
    {
        $bowelLog = $this->ownedLog($request, $log);
        $bowelLog->fill($request->validated());
        $bowelLog->save();

        return new BowelLogResource($bowelLog->refresh());
    }

    public function destroy(Request $request, int $log): JsonResponse
    {
        $bowelLog = $this->ownedLog($request, $log);
        abort_if(
            $bowelLog->logged_at->lt(now()->subDays(30)),
            422,
            'Jejak hanya dapat dihapus hingga 30 hari ke belakang.',
        );
        $bowelLog->delete();

        return response()->json(['message' => 'Jejak berhasil dihapus.']);
    }

    private function ownedLog(Request $request, int $log): BowelLog
    {
        return $request->user()->bowelLogs()->findOrFail($log);
    }
}
