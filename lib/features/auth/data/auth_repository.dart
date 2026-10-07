import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  ),
);

final authProvider = AsyncNotifierProvider<AuthController, UserSession?>(
  AuthController.new,
);

class UserSession {
  const UserSession({
    required this.id,
    required this.alias,
    required this.email,
  });

  final String id;
  final String alias;
  final String email;
}

class AuthRepository {
  AuthRepository(this._api, this._storage);

  final ApiClient _api;
  final FlutterSecureStorage _storage;

  Future<UserSession?> loadSession() async {
    final token = await _api.readToken();
    if (token == null) return null;
    final alias = await _storage.read(key: 'user_alias');
    final email = await _storage.read(key: 'user_email');
    final id = await _storage.read(key: 'user_id');
    if (alias == null || email == null || id == null) return null;
    return UserSession(id: id, alias: alias, email: email);
  }

  Future<UserSession> login(String email, String password) async {
    final response = await _api.postPublic(
      'login',
      body: {'email': email, 'password': password},
    );
    return _saveSession(response);
  }

  Future<UserSession> register({
    required String alias,
    required String email,
    required String password,
    required int age,
    required bool healthConsent,
    required bool parentalConsent,
  }) async {
    final response = await _api.postPublic(
      'register',
      body: {
        'alias': alias,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'age': age,
        'health_data_consent': healthConsent,
        if (age <= 16) 'parental_consent': parentalConsent,
      },
    );
    return _saveSession(response);
  }

  Future<bool> logout() async {
    var revoked = true;
    try {
      await _api.post('logout');
    } on http.ClientException {
      revoked = false;
    } on TimeoutException {
      revoked = false;
    } finally {
      await _storage.delete(key: 'api_token');
      await _storage.delete(key: 'user_alias');
      await _storage.delete(key: 'user_email');
      await _storage.delete(key: 'user_id');
    }
    return revoked;
  }

  Future<UserSession> _saveSession(Map<String, dynamic> response) async {
    final token = response['token'] as String;
    final user = response['data'] as Map<String, dynamic>;
    final id = (user['id'] as int).toString();
    final alias = user['alias'] as String;
    final email = user['email'] as String;

    await _storage.write(key: 'api_token', value: token);
    await _storage.write(key: 'user_alias', value: alias);
    await _storage.write(key: 'user_email', value: email);
    await _storage.write(key: 'user_id', value: id);
    return UserSession(id: id, alias: alias, email: email);
  }
}

class AuthController extends AsyncNotifier<UserSession?> {
  @override
  Future<UserSession?> build() =>
      ref.watch(authRepositoryProvider).loadSession();

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email, password),
    );
  }

  Future<void> register({
    required String alias,
    required String email,
    required String password,
    required int age,
    required bool healthConsent,
    required bool parentalConsent,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .register(
            alias: alias,
            email: email,
            password: password,
            age: age,
            healthConsent: healthConsent,
            parentalConsent: parentalConsent,
          ),
    );
  }

  Future<bool> logout() async {
    try {
      return await ref.read(authRepositoryProvider).logout();
    } finally {
      state = const AsyncData(null);
    }
  }
}
