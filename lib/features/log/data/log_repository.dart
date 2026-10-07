import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../../core/storage/check_in_summary.dart';
import '../../../core/storage/local_store.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/bowel_log.dart';

final logRepositoryProvider = Provider<LogRepository>(
  (ref) => LogRepository(
    ref.watch(localStoreProvider),
    ref.watch(apiClientProvider),
  ),
);

final logsProvider = AsyncNotifierProvider<LogsController, List<BowelLog>>(
  LogsController.new,
);

final waterProvider = AsyncNotifierProvider<WaterController, int>(
  WaterController.new,
);

final checkInProvider =
    AsyncNotifierProvider<CheckInController, CheckInSummary>(
      CheckInController.new,
    );

class SyncResult {
  const SyncResult({required this.online});

  final bool online;
}

class LogRepository {
  LogRepository(this._store, this._api);

  final LocalStore _store;
  final ApiClient _api;

  Future<List<BowelLog>> localLogs(String ownerId) => _store.logs(ownerId);

  Future<SyncResult> sync(String ownerId) async {
    if (ownerId == 'guest') return const SyncResult(online: false);
    final token = await _api.readToken();
    if (token == null) return const SyncResult(online: false);

    try {
      for (final action in await _store.pendingActions(ownerId)) {
        final operation = action['action']! as String;
        final localId = action['local_id']! as String;
        final remoteId = action['remote_id'] as int?;
        final payload = action['payload'] as Map<String, dynamic>? ?? const {};

        if (operation == 'create') {
          final response = await _api.post('logs', body: payload);
          final data = response['data'] as Map<String, dynamic>;
          await _store.markSynced(localId, data['id'] as int);
        } else if (operation == 'update' && remoteId != null) {
          final response = await _api.put('logs/$remoteId', body: payload);
          final data = response['data'] as Map<String, dynamic>;
          await _store.markSynced(localId, data['id'] as int);
        } else if (operation == 'delete' && remoteId != null) {
          await _api.delete('logs/$remoteId');
          await _store.markDeleted(localId);
        }
      }

      final response = await _api.get('logs?per_page=100');
      final data = response['data'] as List<dynamic>;
      for (final item in data.cast<Map<String, dynamic>>()) {
        await _store.importRemote(BowelLog.fromApi(item, ownerId: ownerId));
      }
      return const SyncResult(online: true);
    } on http.ClientException {
      return const SyncResult(online: false);
    } on TimeoutException {
      return const SyncResult(online: false);
    }
  }

  Future<void> save(BowelLog log, {required bool isNew}) =>
      _store.save(log, action: isNew ? 'create' : 'update');

  Future<void> remove(BowelLog log) => _store.remove(log);
}

class LogsController extends AsyncNotifier<List<BowelLog>> {
  @override
  Future<List<BowelLog>> build() {
    ref.watch(authProvider);
    return ref.watch(logRepositoryProvider).localLogs(_ownerId);
  }

  String get _ownerId => ref.read(authProvider).asData?.value?.id ?? 'guest';

  Future<SyncResult> refresh() async {
    final repository = ref.read(logRepositoryProvider);
    final result = await repository.sync(_ownerId);
    state = AsyncData(await repository.localLogs(_ownerId));
    return result;
  }

  Future<SyncResult> save(BowelLog log, {required bool isNew}) async {
    final repository = ref.read(logRepositoryProvider);
    await repository.save(log.copyWith(ownerId: _ownerId), isNew: isNew);
    state = AsyncData(await repository.localLogs(_ownerId));
    final result = await repository.sync(_ownerId);
    state = AsyncData(await repository.localLogs(_ownerId));
    return result;
  }

  Future<SyncResult> remove(BowelLog log) async {
    final repository = ref.read(logRepositoryProvider);
    await repository.remove(log);
    state = AsyncData(await repository.localLogs(_ownerId));
    final result = await repository.sync(_ownerId);
    state = AsyncData(await repository.localLogs(_ownerId));
    return result;
  }
}

class WaterController extends AsyncNotifier<int> {
  @override
  Future<int> build() {
    ref.watch(authProvider);
    return ref.watch(localStoreProvider).waterToday(_ownerId);
  }

  String get _ownerId => ref.read(authProvider).asData?.value?.id ?? 'guest';

  Future<void> addGlass() async {
    final value = await ref.read(localStoreProvider).addGlass(_ownerId);
    state = AsyncData(value);
  }
}

class CheckInController extends AsyncNotifier<CheckInSummary> {
  @override
  Future<CheckInSummary> build() {
    ref.watch(authProvider);
    return ref.watch(localStoreProvider).checkInSummary(_ownerId);
  }

  String get _ownerId => ref.read(authProvider).asData?.value?.id ?? 'guest';

  Future<void> checkIn(String status) async {
    final store = ref.read(localStoreProvider);
    await store.recordCheckIn(_ownerId, status);
    state = AsyncData(await store.checkInSummary(_ownerId));
  }
}
