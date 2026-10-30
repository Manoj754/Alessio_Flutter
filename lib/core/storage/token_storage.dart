import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the session tokens in the platform's secure store (Keychain on iOS,
/// Keystore-backed storage on Android) — never in SharedPreferences, which is
/// plain text on disk.
///
/// The access token is also cached in memory so every API call doesn't pay a
/// platform-channel round trip to read it.
class TokenStorage {
  final FlutterSecureStorage _storage;
  TokenStorage(this._storage);

  static const _accessKey = 'auth_access_token';
  static const _refreshKey = 'auth_refresh_token';

  String? _accessCache;

  Future<String?> readAccessToken() async {
    return _accessCache ??= await _safeRead(_accessKey);
  }

  Future<String?> readRefreshToken() => _safeRead(_refreshKey);

  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessCache = accessToken;
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  /// Wipe both tokens (sign-out, or a session the server no longer accepts).
  Future<void> clear() async {
    _accessCache = null;
    try {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
    } catch (_) {
      // Nothing stored, or the store is unavailable — either way the user is
      // signed out in memory, which is what matters.
    }
  }

  /// A corrupted keystore entry (e.g. after an Android backup restore) throws
  /// on read. Treat it as "no session" instead of crashing the launch.
  Future<String?> _safeRead(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }
}

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(const FlutterSecureStorage()),
);
