import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_model.dart';
import '../services/auth_service.dart';

const _storage = FlutterSecureStorage();

// Watches current logged-in user — null = not authenticated
final authStateProvider = FutureProvider<AuthUser?>((ref) async {
  final token = await _storage.read(key: 'access_token');
  if (token == null) return null;
  return ref.read(authServiceProvider).getMe();
});

final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref));
