/// Everything the app needs to know about the DummyJSON backend.
///
/// Kept in one place so a staging/production switch (or a different API) only
/// touches this file — repositories never hardcode a URL or path.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://dummyjson.com';

  // Auth
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String refresh = '/auth/refresh';

  // Products
  static const String products = '/products';
  static const String productSearch = '/products/search';
  static String product(int id) => '/products/$id';

  /// Lifetime requested for a fresh access token. DummyJSON defaults to 60;
  /// asking explicitly keeps the refresh behaviour predictable.
  static const int tokenExpiresInMins = 60;

  /// Products fetched per page. Small enough that the first screen paints
  /// fast, large enough that a fling doesn't hit the end immediately.
  static const int pageSize = 20;

  /// A request that hasn't answered by now is treated as a network failure,
  /// so the user sees a retry instead of an endless spinner.
  static const Duration requestTimeout = Duration(seconds: 20);
}
