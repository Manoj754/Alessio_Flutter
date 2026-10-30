import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterapp/core/localization/app_strings.dart';
import 'package:flutterapp/core/network/api_exception.dart';
import 'package:flutterapp/features/auth/viewmodel/auth_controller.dart';

/// The login form's submit status: idle (`AsyncData`), submitting
/// (`AsyncLoading`) or failed (`AsyncError` carrying a user-safe message).
///
/// Navigation is NOT done here — a successful login flips
/// [authControllerProvider], and the router redirects on that.
final loginControllerProvider =
    AutoDisposeNotifierProvider<LoginController, AsyncValue<void>>(
      LoginController.new,
    );

class LoginController extends AutoDisposeNotifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> submit({
    required String username,
    required String password,
  }) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(username: username, password: password);
      state = const AsyncData(null);
    } on ApiException catch (e, st) {
      state = AsyncError(e.message, st);
    } catch (_, st) {
      state = AsyncError(AppStrings.errorGeneric, st);
    }
  }

  /// Clear a shown error once the user edits a field again.
  void clearError() {
    if (state.hasError) state = const AsyncData(null);
  }
}
