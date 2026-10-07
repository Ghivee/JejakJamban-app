import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return ApiClient(client, ref.watch(secureStorageProvider));
});

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message, [this.errors = const {}]);

  final int statusCode;
  final String message;
  final Map<String, dynamic> errors;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this._client, this._storage);

  final http.Client _client;
  final FlutterSecureStorage _storage;

  Uri _uri(String path) {
    final base = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse('$base/$path');
  }

  Future<String?> readToken() => _storage.read(key: 'api_token');

  Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) => _send('POST', path, body: body);

  Future<Map<String, dynamic>> postPublic(
    String path, {
    required Map<String, dynamic> body,
  }) => _send('POST', path, body: body, authenticated: false);

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) =>
      _send('PUT', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final token = authenticated ? await readToken() : null;
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final request = http.Request(method, _uri(path))..headers.addAll(headers);
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamedResponse = await _client
        .send(request)
        .timeout(const Duration(seconds: 12));
    final response = await http.Response.fromStream(streamedResponse);
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        decoded['message'] as String? ?? 'Permintaan ke server gagal.',
        decoded['errors'] as Map<String, dynamic>? ?? const {},
      );
    }

    return decoded;
  }
}
