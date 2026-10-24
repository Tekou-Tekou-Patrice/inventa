import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

abstract interface class SessionCredentialStore {
  Future<String?> readUsername();
  Future<String?> readPassword();
  Future<String?> readIdentity();
  Future<void> save(String username, String password);
  Future<void> saveIdentity(String identity);
  Future<void> clear();
}

class SecureSessionCredentialStore implements SessionCredentialStore {
  SecureSessionCredentialStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _usernameKey = 'inventa.session.username';
  static const _passwordKey = 'inventa.session.password';
  static const _identityKey = 'inventa.session.identity';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readUsername() => _storage.read(key: _usernameKey);

  @override
  Future<String?> readPassword() => _storage.read(key: _passwordKey);

  @override
  Future<String?> readIdentity() => _storage.read(key: _identityKey);

  @override
  Future<void> save(String username, String password) async {
    await _storage.write(key: _usernameKey, value: username);
    await _storage.write(key: _passwordKey, value: password);
  }

  @override
  Future<void> saveIdentity(String identity) =>
      _storage.write(key: _identityKey, value: identity);

  @override
  Future<void> clear() async {
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _passwordKey);
    await _storage.delete(key: _identityKey);
  }
}

class PlantationApi {
  PlantationApi({
    http.Client? client,
    String? baseUrl,
    SessionCredentialStore? sessionCredentialStore,
  }) : _client = client ?? http.Client(),
       _sessionCredentialStore =
           sessionCredentialStore ?? SecureSessionCredentialStore(),
       baseUrl = baseUrl ?? _defaultBaseUrl;

  final http.Client _client;
  final SessionCredentialStore _sessionCredentialStore;
  final String baseUrl;
  String? _authorization;

  static String get _defaultBaseUrl {
    const configuredUrl = String.fromEnvironment('INVENTA_API_URL');
    if (configuredUrl.isNotEmpty) return configuredUrl;
    if (kIsWeb) return 'http://localhost:8006';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8006'
        : 'http://localhost:8006';
  }

  bool get isAuthenticated => _authorization != null;
  String? get authenticatedUsername {
    final authorization = _authorization;
    if (authorization == null) return null;
    final encoded = authorization.substring('Basic '.length);
    return utf8.decode(base64Decode(encoded)).split(':').first;
  }

  Future<bool> canRegisterDirector() async {
    final response = await _publicRequest(
      'GET',
      '/api/auth/director-registration',
    );
    final result = _decodeMap(response.body);
    if (result['available'] is! bool) {
      throw const ApiException('Réponse d’inscription directeur invalide.');
    }
    return result['available'] as bool;
  }

  Future<void> registerDirector({
    required String username,
    required String password,
    required String phoneNumber,
  }) async {
    await _publicRequest(
      'POST',
      '/api/auth/register-director',
      body: {
        'username': username.trim(),
        'password': password,
        'phoneNumber': phoneNumber.trim(),
      },
    );
  }

  Future<http.Response> _publicRequest(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    late http.Response response;
    try {
      final uri = Uri.parse('$baseUrl$path');
      final headers = {
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
      };
      final request = switch (method) {
        'GET' => _client.get(uri, headers: headers),
        'POST' => _client.post(uri, headers: headers, body: jsonEncode(body)),
        _ => throw ArgumentError.value(
          method,
          'method',
          'Unsupported HTTP method',
        ),
      };
      response = await request.timeout(const Duration(seconds: 15));
    } on Exception catch (error) {
      if (error is ApiException) rethrow;
      throw const ApiException(
        'Impossible de joindre le serveur. Vérifiez le réseau et réessayez.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _errorMessage(response.body),
        statusCode: response.statusCode,
      );
    }
    return response;
  }

  void clearAuthorization() {
    _authorization = null;
  }

  Future<void> clearSession() async {
    clearAuthorization();
    await _sessionCredentialStore.clear();
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final normalizedUsername = username.trim();
    final authorization =
        'Basic ${base64Encode(utf8.encode('$normalizedUsername:$password'))}';
    late http.Response response;
    try {
      response = await _client
          .get(
            Uri.parse('$baseUrl/api/auth/me'),
            headers: {
              'Authorization': authorization,
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw const ApiException(
        'Impossible de joindre le serveur. Vérifiez le réseau et réessayez.',
      );
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const ApiException(
        'Identifiant ou mot de passe incorrect.',
        statusCode: 401,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'Le serveur a répondu ${response.statusCode}. Réessayez plus tard.',
        statusCode: response.statusCode,
      );
    }
    await _sessionCredentialStore.save(normalizedUsername, password);
    _authorization = authorization;
    await _sessionCredentialStore.saveIdentity(response.body);
    return _decodeMap(response.body);
  }

  Future<Map<String, dynamic>?> restoreSession() async {
    final username = await _sessionCredentialStore.readUsername();
    final password = await _sessionCredentialStore.readPassword();
    if (username == null && password == null) return null;
    if (username == null || username.isEmpty || password == null) {
      await _sessionCredentialStore.clear();
      return null;
    }
    try {
      return await login(username, password);
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await clearSession();
        return null;
      }
      // If the error is a network/connectivity issue, try using a cached identity
      if (error.statusCode == null) {
        final identityJson = await _sessionCredentialStore.readIdentity();
        if (identityJson != null) {
          _authorization =
              'Basic ${base64Encode(utf8.encode('$username:$password'))}';
          return _decodeMap(identityJson);
        }
      }
      rethrow;
    }
  }

  Future<dynamic> request(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final authorization = _authorization;
    if (authorization == null) {
      throw const ApiException(
        'Votre session a expiré. Veuillez vous reconnecter.',
      );
    }
    final uri = Uri.parse('$baseUrl$path');
    final headers = {
      'Authorization': authorization,
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
    };
    late http.Response response;
    try {
      final request = switch (method) {
        'GET' => _client.get(uri, headers: headers),
        'POST' => _client.post(uri, headers: headers, body: jsonEncode(body)),
        'PUT' => _client.put(uri, headers: headers, body: jsonEncode(body)),
        'DELETE' => _client.delete(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        ),
        _ => throw ArgumentError.value(
          method,
          'method',
          'Unsupported HTTP method',
        ),
      };
      response = await request.timeout(const Duration(seconds: 20));
    } on Exception catch (error) {
      if (error is ApiException) rethrow;
      throw const ApiException(
        'Impossible de joindre le serveur. Vérifiez le réseau et réessayez.',
      );
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw ApiException(
        'Vous n’avez pas accès à cette action.',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _errorMessage(response.body);
      throw ApiException(message, statusCode: response.statusCode);
    }
    if (response.body.trim().isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<dynamic> getBudgetSnapshot({bool fieldManager = false}) =>
      request('GET', fieldManager ? '/api/budgets/field' : '/api/budgets');

  Future<dynamic> setBudgetLimit(int fundingLimit) => request(
    'PUT',
    '/api/budgets/limit',
    body: {'fundingLimit': fundingLimit},
  );

  Future<dynamic> addBudgetFunding({required int amount, String? note}) =>
      request(
        'POST',
        '/api/budgets/funding',
        body: {
          'amount': amount,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        },
      );

  Future<dynamic> allocateFieldBudget({
    required int fieldId,
    required int amount,
    String? note,
  }) => request(
    'POST',
    '/api/budgets/allocations',
    body: {
      'fieldId': fieldId,
      'amount': amount,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    },
  );

  Future<dynamic> recordAssistantExpense(
    Map<String, Object?> payload,
    String idempotencyKey,
  ) => request(
    'POST',
    '/api/expenses',
    body: {...payload, 'idempotencyKey': idempotencyKey},
  );

  Future<dynamic> recordFieldBudgetExpense(
    Map<String, Object?> payload,
    String idempotencyKey,
  ) => request(
    'POST',
    '/api/expenses/field-budget',
    body: {...payload, 'idempotencyKey': idempotencyKey},
  );

  Future<dynamic> synchronizeOfflineExpense(
    Map<String, Object?> payload,
    String idempotencyKey,
  ) => request(
    'POST',
    '/api/expenses/offline-sync',
    body: {...payload, 'idempotencyKey': idempotencyKey},
  );

  Future<void> close() async {
    clearAuthorization();
    _client.close();
  }

  Map<String, dynamic> _decodeMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const ApiException('Réponse d’authentification invalide.');
  }

  String _errorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'] ?? decoded['message'];
        if (detail is String && detail.isNotEmpty) return detail;
      }
    } on FormatException catch (error) {
      debugPrint('API returned a non-JSON error response: $error');
    }
    return 'La demande a échoué. Vérifiez les informations puis réessayez.';
  }
}
