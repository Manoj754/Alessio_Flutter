import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterapp/features/auth/model/auth_state.dart';
import 'package:flutterapp/features/auth/view/login_screen.dart';
import 'package:flutterapp/features/auth/viewmodel/auth_controller.dart';
import 'package:flutterapp/features/products/model/product.dart';
import 'package:flutterapp/features/products/view/product_detail_screen.dart';
import 'package:flutterapp/features/products/view/product_list_screen.dart';
import 'package:flutterapp/features/splash/view/splash_screen.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String login = '/login';
  static const String products = '/products';
  static String productDetail(int id) => '$products/$id';
}

/// Single-authority routing. The router — not individual screens — decides
/// where the user lands, from [authControllerProvider]. Screens never navigate
/// after login/logout themselves, so they can't race the redirect.
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ValueNotifier<AuthState>(ref.read(authControllerProvider));
  ref.listen(authControllerProvider, (_, next) => auth.value = next);
  ref.onDispose(auth.dispose);

  return GoRouter(
    initialLocation: AppRouter.splash,
    refreshListenable: auth,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      switch (auth.value.status) {
        case AuthStatus.unknown:
          // Still checking the stored session — hold on the splash.
          return loc == AppRouter.splash ? null : AppRouter.splash;
        case AuthStatus.unauthenticated:
          return loc == AppRouter.login ? null : AppRouter.login;
        case AuthStatus.authenticated:
          if (loc == AppRouter.splash || loc == AppRouter.login) {
            return AppRouter.products;
          }
          return null;
      }
    },
    routes: [
      GoRoute(
        path: AppRouter.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRouter.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRouter.products,
        builder: (context, state) => const ProductListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => ProductDetailScreen(
              productId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
              // The tapped list item, so the page paints instantly. Absent on
              // a deep link — the screen then loads from scratch.
              initial: state.extra is Product ? state.extra as Product : null,
            ),
          ),
        ],
      ),
    ],
  );
});
