import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterapp/core/network/api_client.dart';
import 'package:flutterapp/core/network/api_exception.dart';
import 'package:flutterapp/features/auth/model/auth_state.dart';
import 'package:flutterapp/features/auth/model/auth_user.dart';
import 'package:flutterapp/features/auth/service/auth_repository.dart';

/// The single source of truth for "who is signed in". The router listens to
/// this to decide between splash, login and the product screens.
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    // A refresh that fails mid-session means the server dropped us — sign
    // out so the router sends the user back to login.
    final sub = ref
        .watch(apiClientProvider)
        .sessionExpired
        .listen((_) => state = const AuthState.unauthenticated());
    ref.onDispose(sub.cancel);

    unawaited(_restore());
    return const AuthState.unknown();
  }

  Future<void> _restore() async {
    try {
      final user = await _repo.restore();
      state = user == null
          ? const AuthState.unauthenticated()
          : AuthState.authenticated(user);
    } on ApiException {
      // Offline at launch with a stored token: stay signed in; screens show
      // their own offline state and recover on retry.
      state = const AuthState.authenticated(null);
    }
  }

  /// Throws [ApiException] with a user-safe message on failure.
  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    final user = await _repo.login(username: username, password: password);
    state = AuthState.authenticated(user);
    return user;
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState.unauthenticated();
  }
}
