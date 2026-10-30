import 'package:flutterapp/features/auth/model/auth_user.dart';

enum AuthStatus {
  /// Launch: the stored session hasn't been checked yet (splash shows).
  unknown,
  authenticated,
  unauthenticated,
}

/// The app-wide session the router redirects on.
///
/// [user] can be null while [AuthStatus.authenticated]: a stored session
/// restored while offline is still a session — the user lands on products
/// (which shows its own offline state) instead of being bounced to login.
class AuthState {
  final AuthStatus status;
  final AuthUser? user;

  const AuthState._(this.status, [this.user]);

  const AuthState.unknown() : this._(AuthStatus.unknown);
  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated);
  const AuthState.authenticated(AuthUser? user)
    : this._(AuthStatus.authenticated, user);

  bool get isAuthenticated => status == AuthStatus.authenticated;
}
