import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../features/log/domain/bowel_log.dart';
import 'check_in_summary.dart';
import '../domain/health_rules.dart';
import 'local_store_memory.dart';

class PlatformLocalStore {
  PlatformLocalStore(this._secureStorage)
    : _memory = Platform.isAndroid || Platform.isIOS
          ? null
          : MemoryLocalStore(_secureStorage);

  final FlutterSecureStorage _secureStorage;
  final MemoryLocalStore? _memory;
  Future<Database>? _database;

  Future<Database> get _db => _database ??= _open();

  Future<Database> _open() async {
    var key = await _secureStorage.read(key: 'local_database_key');
    if (key == null) {
      final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
      key = base64Url.encode(bytes);
      await _secureStorage.write(key: 'local_database_key', value: key);
    }

    final directory = await getApplicationDocumentsDirectory();
    final databasePath = p.join(directory.path, 'jejak_jamban.db');

    return openDatabase(
      databasePath,
      password: key,
      version: 1,
      onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE bowel_logs (
            id TEXT PRIMARY KEY,
            client_id TEXT NOT NULL,
            owner_id TEXT NOT NULL,
            remote_id INTEGER,
            logged_at TEXT NOT NULL,
            bristol_type INTEGER NOT NULL,
            volume TEXT,
            duration_min INTEGER,
            color TEXT,
            sensations TEXT NOT NULL,
            mood INTEGER,
            triggers TEXT NOT NULL,
            note TEXT,
            sync_status TEXT NOT NULL,
            deleted INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await database.execute('''
          CREATE TABLE sync_queue (
            local_id TEXT PRIMARY KEY,
            owner_id TEXT NOT NULL,
            action TEXT NOT NULL,
            remote_id INTEGER,
            payload TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE hydration (
            owner_id TEXT NOT NULL,
            day TEXT NOT NULL,
            milliliters INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY(owner_id, day)
          )
        ''');
        await database.execute('''
          CREATE TABLE daily_checkins (
            owner_id TEXT NOT NULL,
            day TEXT NOT NULL,
            status TEXT NOT NULL,
            PRIMARY KEY(owner_id, day)
          )
        ''');
        await database.execute(
          'CREATE INDEX bowel_logs_logged_at_idx ON bowel_logs(logged_at)',
        );
      },
    );
  }

  Future<List<BowelLog>> logs(String ownerId) async {
    if (_memory case final memory?) return memory.logs(ownerId);
    final rows = await (await _db).query(
      'bowel_logs',
      where: 'deleted = 0 AND owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'logged_at DESC',
    );
    return rows.map(BowelLog.fromStorage).toList();
  }

  Future<void> save(BowelLog log, {required String action}) async {
    if (_memory case final memory?) {
      await memory.save(log, action: action);
      return;
    }
    final database = await _db;
    await database.transaction((transaction) async {
      await transaction.insert(
        'bowel_logs',
        log.copyWith(syncStatus: 'pending').toStorage(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      final pending = await transaction.query(
        'sync_queue',
        columns: ['action'],
        where: 'local_id = ?',
        whereArgs: [log.id],
      );
      final finalAction =
          pending.isNotEmpty && pending.first['action'] == 'create'
          ? 'create'
          : action;
      await transaction.insert('sync_queue', {
        'local_id': log.id,
        'owner_id': log.ownerId,
        'action': finalAction,
        'remote_id': log.remoteId,
        'payload': jsonEncode(log.toApiJson()),
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> remove(BowelLog log) async {
    if (_memory case final memory?) {
      await memory.remove(log);
      return;
    }
    final database = await _db;
    await database.transaction((transaction) async {
      if (log.remoteId == null) {
        await transaction.delete(
          'sync_queue',
          where: 'local_id = ?',
          whereArgs: [log.id],
        );
        await transaction.delete(
          'bowel_logs',
          where: 'id = ?',
          whereArgs: [log.id],
        );
        return;
      }
      await transaction.update(
        'bowel_logs',
        {'deleted': 1, 'sync_status': 'pending'},
        where: 'id = ?',
        whereArgs: [log.id],
      );
      await transaction.insert('sync_queue', {
        'local_id': log.id,
        'owner_id': log.ownerId,
        'action': 'delete',
        'remote_id': log.remoteId,
        'payload': '{}',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<List<Map<String, Object?>>> pendingActions(String ownerId) async {
    if (_memory case final memory?) return memory.pendingActions(ownerId);
    final rows = await (await _db).query(
      'sync_queue',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'created_at ASC',
    );
    return rows
        .map(
          (row) => {...row, 'payload': jsonDecode(row['payload']! as String)},
        )
        .toList();
  }

  Future<void> markSynced(String localId, int remoteId) async {
    if (_memory case final memory?) {
      await memory.markSynced(localId, remoteId);
      return;
    }
    final database = await _db;
    await database.transaction((transaction) async {
      await transaction.update(
        'bowel_logs',
        {'remote_id': remoteId, 'sync_status': 'synced'},
        where: 'id = ?',
        whereArgs: [localId],
      );
      await transaction.delete(
        'sync_queue',
        where: 'local_id = ?',
        whereArgs: [localId],
      );
    });
  }

  Future<void> markDeleted(String localId) async {
    if (_memory case final memory?) {
      await memory.markDeleted(localId);
      return;
    }
    final database = await _db;
    await database.transaction((transaction) async {
      await transaction.delete(
        'sync_queue',
        where: 'local_id = ?',
        whereArgs: [localId],
      );
      await transaction.delete(
        'bowel_logs',
        where: 'id = ?',
        whereArgs: [localId],
      );
    });
  }

  Future<void> importRemote(BowelLog log) async {
    if (_memory case final memory?) {
      await memory.importRemote(log);
      return;
    }
    await (await _db).insert(
      'bowel_logs',
      log.copyWith(syncStatus: 'synced').toStorage(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> addGlass(String ownerId) async {
    if (_memory case final memory?) return memory.addGlass(ownerId);
    final database = await _db;
    final today = _today();
    await database.rawInsert(
      '''
      INSERT INTO hydration(owner_id, day, milliliters) VALUES(?, ?, 250)
      ON CONFLICT(owner_id, day) DO UPDATE SET milliliters = milliliters + 250
      ''',
      [ownerId, today],
    );
    return waterToday(ownerId);
  }

  Future<int> waterToday(String ownerId) async {
    if (_memory case final memory?) return memory.waterToday(ownerId);
    final today = _today();
    final rows = await (await _db).query(
      'hydration',
      columns: ['milliliters'],
      where: 'owner_id = ? AND day = ?',
      whereArgs: [ownerId, today],
    );
    return rows.isEmpty ? 0 : rows.first['milliliters']! as int;
  }

  Future<void> recordCheckIn(String ownerId, String status) async {
    if (_memory case final memory?) {
      await memory.recordCheckIn(ownerId, status);
      return;
    }
    final today = _today();
    await (await _db).insert('daily_checkins', {
      'owner_id': ownerId,
      'day': today,
      'status': status,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<CheckInSummary> checkInSummary(String ownerId) async {
    if (_memory case final memory?) return memory.checkInSummary(ownerId);
    final database = await _db;
    final rows = await database.query(
      'daily_checkins',
      columns: ['day'],
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'day DESC',
    );
    final days = rows.map((row) => row['day']! as String).toSet();
    final today = DateTime.now();
    final todayKey = _today();
    final checkedIn = days.contains(todayKey);
    final streak = calculateStreak(
      checkIns: days.map(DateTime.parse),
      today: today,
    );
    return CheckInSummary(streak: streak.days, checkedInToday: checkedIn);
  }

  String _today() => _dateKey(DateTime.now());

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
