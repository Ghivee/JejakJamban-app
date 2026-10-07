import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'check_in_summary.dart';
import '../../features/log/domain/bowel_log.dart';
import '../domain/health_rules.dart';

class MemoryLocalStore {
  MemoryLocalStore(FlutterSecureStorage secureStorage);

  final Map<String, BowelLog> _logs = {};
  final Map<String, Map<String, Object?>> _outbox = {};
  final Map<String, int> _waterMl = {};
  final Map<String, Map<String, String>> _checkIns = {};

  Future<List<BowelLog>> logs(String ownerId) async =>
      _logs.values
          .where((log) => !log.deleted && log.ownerId == ownerId)
          .toList()
        ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

  Future<void> save(BowelLog log, {required String action}) async {
    _logs[log.id] = log;
    final previous = _outbox[log.id];
    _outbox[log.id] = {
      'local_id': log.id,
      'owner_id': log.ownerId,
      'action': previous?['action'] == 'create' ? 'create' : action,
      'remote_id': log.remoteId,
      'payload': log.toApiJson(),
    };
  }

  Future<void> remove(BowelLog log) async {
    if (log.remoteId == null) {
      _logs.remove(log.id);
      _outbox.remove(log.id);
      return;
    }
    _logs[log.id] = log.copyWith(deleted: true, syncStatus: 'pending');
    _outbox[log.id] = {
      'local_id': log.id,
      'owner_id': log.ownerId,
      'action': 'delete',
      'remote_id': log.remoteId,
      'payload': <String, dynamic>{},
    };
  }

  Future<List<Map<String, Object?>>> pendingActions(String ownerId) async =>
      _outbox.values.where((action) => action['owner_id'] == ownerId).toList();

  Future<void> markSynced(String localId, int remoteId) async {
    final log = _logs[localId];
    if (log != null) {
      _logs[localId] = log.copyWith(remoteId: remoteId, syncStatus: 'synced');
    }
    _outbox.remove(localId);
  }

  Future<void> markDeleted(String localId) async {
    _logs.remove(localId);
    _outbox.remove(localId);
  }

  Future<void> importRemote(BowelLog log) async {
    _logs[log.id] = log.copyWith(syncStatus: 'synced');
  }

  Future<int> addGlass(String ownerId) async {
    final key = '$ownerId:${_today()}';
    _waterMl.update(key, (value) => value + 250, ifAbsent: () => 250);
    return _waterMl[key]!;
  }

  Future<int> waterToday(String ownerId) async {
    final key = '$ownerId:${_today()}';
    return _waterMl[key] ?? 0;
  }

  Future<void> recordCheckIn(String ownerId, String status) async {
    _checkIns.putIfAbsent(ownerId, () => {})[_today()] = status;
  }

  Future<CheckInSummary> checkInSummary(String ownerId) async {
    final checkIns = _checkIns[ownerId] ?? const <String, String>{};
    final checkedIn = checkIns.containsKey(_today());
    final streak = calculateStreak(
      checkIns: checkIns.keys.map(DateTime.parse),
      today: DateTime.now(),
    );
    return CheckInSummary(streak: streak.days, checkedInToday: checkedIn);
  }

  String _today() => _dateKey(DateTime.now());

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class PlatformLocalStore extends MemoryLocalStore {
  PlatformLocalStore(super.secureStorage);
}
