import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterapp/core/config/api_config.dart';
import 'package:flutterapp/core/localization/app_strings.dart';
import 'package:flutterapp/core/network/api_client.dart';
import 'package:flutterapp/core/network/api_exception.dart';
import 'package:flutterapp/core/storage/token_storage.dart';
import 'package:flutterapp/features/auth/model/auth_user.dart';

/// Talks to DummyJSON's auth endpoints and owns where the tokens live. The
/// viewmodel never touches tokens directly — it only asks "sign in", "who am
/// I", "sign out".
class AuthRepository {
  final ApiClient _api;
  final TokenStorage _tokens;
  const AuthRepository(this._api, this._tokens);

  /// Sign in and persist the returned tokens securely.
  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    try {
      final json = await _api.post(
        ApiConfig.login,
        authorized: false,
        body: {
          'username': username.trim(),
          'password': password,
          'expiresInMins': ApiConfig.tokenExpiresInMins,
        },
      );
      await _tokens.save(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );
      return AuthUser.fromJson(json);
    } on ApiException catch (e) {
      // DummyJSON answers bad credentials with 400 (not 401).
      if (e.statusCode == 400) {
        throw ApiException(
          ApiErrorType.unauthorized,
          AppStrings.invalidCredentials,
          statusCode: 400,
        );
      }
      rethrow;
    }
  }

  /// Restore the session on launch: null when no token is stored or the
  /// server rejects it (after the client's own refresh attempt).
  Future<AuthUser?> restore() async {
    final token = await _tokens.readAccessToken();
    if (token == null) return null;
    try {
      return AuthUser.fromJson(await _api.get(ApiConfig.me));
    } on ApiException catch (e) {
      if (e.type == ApiErrorType.unauthorized) {
        await _tokens.clear();
        return null;
      }
      rethrow;
    }
  }

  Future<void> logout() => _tokens.clear();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  ),
);
