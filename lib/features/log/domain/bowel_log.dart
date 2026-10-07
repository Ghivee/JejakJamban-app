import 'dart:convert';

class BowelLog {
  const BowelLog({
    required this.id,
    required this.clientId,
    required this.bristolType,
    required this.loggedAt,
    this.ownerId = 'guest',
    this.remoteId,
    this.volume,
    this.durationMin,
    this.color,
    this.sensations = const [],
    this.mood,
    this.triggers = const [],
    this.note,
    this.syncStatus = 'pending',
    this.deleted = false,
  });

  final String id;
  final String clientId;
  final String ownerId;
  final int? remoteId;
  final int bristolType;
  final DateTime loggedAt;
  final String? volume;
  final int? durationMin;
  final String? color;
  final List<String> sensations;
  final int? mood;
  final List<String> triggers;
  final String? note;
  final String syncStatus;
  final bool deleted;

  BowelLog copyWith({
    int? remoteId,
    String? ownerId,
    String? syncStatus,
    bool? deleted,
  }) => BowelLog(
    id: id,
    clientId: clientId,
    ownerId: ownerId ?? this.ownerId,
    remoteId: remoteId ?? this.remoteId,
    bristolType: bristolType,
    loggedAt: loggedAt,
    volume: volume,
    durationMin: durationMin,
    color: color,
    sensations: sensations,
    mood: mood,
    triggers: triggers,
    note: note,
    syncStatus: syncStatus ?? this.syncStatus,
    deleted: deleted ?? this.deleted,
  );

  Map<String, dynamic> toApiJson() => {
    'client_id': clientId,
    'logged_at': loggedAt.toUtc().toIso8601String(),
    'bristol_type': bristolType,
    'volume': volume,
    'duration_min': durationMin,
    'color': color,
    'sensations': sensations,
    'mood': mood,
    'triggers': triggers,
    'note': note,
  };

  Map<String, Object?> toStorage() => {
    'id': id,
    'client_id': clientId,
    'owner_id': ownerId,
    'remote_id': remoteId,
    'logged_at': loggedAt.toUtc().toIso8601String(),
    'bristol_type': bristolType,
    'volume': volume,
    'duration_min': durationMin,
    'color': color,
    'sensations': jsonEncode(sensations),
    'mood': mood,
    'triggers': jsonEncode(triggers),
    'note': note,
    'sync_status': syncStatus,
    'deleted': deleted ? 1 : 0,
  };

  factory BowelLog.fromStorage(Map<String, Object?> row) => BowelLog(
    id: row['id']! as String,
    clientId: row['client_id']! as String,
    ownerId: row['owner_id']! as String,
    remoteId: row['remote_id'] as int?,
    bristolType: row['bristol_type']! as int,
    loggedAt: DateTime.parse(row['logged_at']! as String).toLocal(),
    volume: row['volume'] as String?,
    durationMin: row['duration_min'] as int?,
    color: row['color'] as String?,
    sensations: _decodeStrings(row['sensations']),
    mood: row['mood'] as int?,
    triggers: _decodeStrings(row['triggers']),
    note: row['note'] as String?,
    syncStatus: row['sync_status']! as String,
    deleted: row['deleted'] == 1,
  );

  factory BowelLog.fromApi(
    Map<String, dynamic> json, {
    required String ownerId,
  }) => BowelLog(
    id: json['client_id'] as String? ?? 'remote-${json['id']}',
    clientId: json['client_id'] as String? ?? 'remote-${json['id']}',
    ownerId: ownerId,
    remoteId: json['id'] as int,
    bristolType: json['bristol_type'] as int,
    loggedAt: DateTime.parse(json['logged_at'] as String).toLocal(),
    volume: json['volume'] as String?,
    durationMin: json['duration_min'] as int?,
    color: json['color'] as String?,
    sensations: _decodeStrings(json['sensations']),
    mood: json['mood'] as int?,
    triggers: _decodeStrings(json['triggers']),
    note: json['note'] as String?,
    syncStatus: 'synced',
  );

  static List<String> _decodeStrings(Object? value) {
    if (value is List) return value.cast<String>();
    if (value is String) {
      return (jsonDecode(value) as List<dynamic>).cast<String>();
    }
    return const [];
  }
}
