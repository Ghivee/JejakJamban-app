import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';

import 'local_store_memory.dart'
    if (dart.library.io) 'local_store_sqlite.dart'
    as platform;

final localStoreProvider = Provider<LocalStore>(
  (ref) => LocalStore(ref.watch(secureStorageProvider)),
);

class LocalStore extends platform.PlatformLocalStore {
  LocalStore(super.secureStorage);
}

String createLocalId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
  final value = hex.join();
  return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
      '${value.substring(12, 16)}-${value.substring(16, 20)}-'
      '${value.substring(20)}';
}
