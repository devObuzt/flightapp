import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api/api_client.dart';
import '../models/auth_model.dart';

const _storage = FlutterSecureStorage();

class AuthService {
  AuthService(this._ref);
  final Ref _ref;

  Future<AuthTokens> login({
    required String identifier,
    required String password,
  }) async {
    final dio = _ref.read(dioProvider);
    final res = await dio.post('/auth/login', data: {
      'identifier': identifier,
      'password': password,
      'platform': 'flutter_android',
    });
    final tokens = AuthTokens.fromJson(res.data as Map<String, dynamic>);
    await _saveTokens(tokens);
    return tokens;
  }

  Future<AuthTokens> register({
    required String fullName,
    String? email,
    String? phone,
    required String password,
  }) async {
    final dio = _ref.read(dioProvider);
    final res = await dio.post('/auth/register', data: {
      'full_name': fullName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'password': password,
    });
    final tokens = AuthTokens.fromJson(res.data as Map<String, dynamic>);
    await _saveTokens(tokens);
    return tokens;
  }

  Future<AuthUser> getMe() async {
    final dio = _ref.read(dioProvider);
    final res = await dio.get('/auth/me');
    return AuthUser.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken != null) {
      try {
        final dio = _ref.read(dioProvider);
        await dio.post('/auth/logout', data: {'refresh_token': refreshToken});
      } catch (_) {}
    }
    await _storage.deleteAll();
  }

  Future<void> _saveTokens(AuthTokens tokens) async {
    await _storage.write(key: 'access_token', value: tokens.accessToken);
    await _storage.write(key: 'refresh_token', value: tokens.refreshToken);
  }
}
