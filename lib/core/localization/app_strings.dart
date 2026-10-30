/// Central place for all user-facing copy.
///
/// Keeping strings here (instead of hardcoding them in widgets) makes it
/// straightforward to migrate to proper Flutter localization later — e.g.
/// `flutter_localizations` + `intl` with `.arb` files and `flutter gen-l10n`.
/// When that happens, these constants can be swapped for `AppLocalizations`
/// lookups without touching widget layout code.
class AppStrings {
  AppStrings._();

  static const String appName = 'Shopline';

  // Login screen
  static const String loginTitle = 'Welcome back';
  static const String loginSubtitle = 'Sign in to continue shopping.';
  static const String usernameLabel = 'Username';
  static const String usernameHint = 'Enter your username';
  static const String passwordLabel = 'Password';
  static const String passwordHint = 'Enter your password';
  static const String logIn = 'Sign in';
  static const String usernameRequired = 'Enter your username.';
  static const String passwordRequired = 'Enter your password.';
  static const String invalidCredentials =
      "That username and password don't match. Try again.";

  // Product list
  static const String productsTitle = 'Discover';
  static String hello(String name) => 'Hello, $name';
  static const String helloFallback = 'Hello there';
  static String productCount(int n) => '$n ${n == 1 ? 'product' : 'products'}';
  static const String searchHint = 'Search products, brands…';
  static const String clearSearch = 'Clear search';
  static String searchResults(int n, String query) =>
      '$n ${n == 1 ? 'result' : 'results'} for "$query"';
  static String noResultsTitle(String query) => 'No results for "$query"';
  static const String noResultsMessage =
      'Check the spelling or try a more general word.';
  static const String loadingMore = 'Loading more';
  static const String productsEmptyTitle = 'Nothing here yet';
  static const String productsEmptyMessage =
      'No products to show right now. Pull down to refresh.';
  static const String productsErrorTitle = "Couldn't load products";
  static const String loadMoreFailed = "Couldn't load more.";
  static const String endOfList = "You've seen it all";
  static const String account = 'Account';
  static const String logOut = 'Log out';

  // Product detail
  static String inStock(int n) => 'In stock · $n available';
  static String lowStock(int n) => 'Only $n left in stock';
  static const String outOfStock = 'Out of stock';
  static String youSave(String amount) => 'You save $amount';
  static String reviewCount(int n) => '$n ${n == 1 ? 'review' : 'reviews'}';
  static String basedOnReviews(int n) =>
      'Based on $n ${n == 1 ? 'review' : 'reviews'}';
  static const String description = 'Description';
  static const String readMore = 'Read more';
  static const String showLess = 'Show less';
  static const String details = 'Details';
  static const String warranty = 'Warranty';
  static const String shipping = 'Shipping';
  static const String returns = 'Returns';
  static const String reviews = 'Reviews';
  static const String noReviews = 'No reviews yet.';
  static const String productErrorTitle = "Couldn't load this product";

  // Errors (user-safe — raw backend text never reaches the screen)
  static const String errorNetwork =
      "You're offline. Check your connection and try again.";
  static const String errorTimeout =
      'This is taking longer than usual. Please try again.';
  static const String errorSessionExpired =
      'Your session has ended. Please log in again.';
  static const String errorNotFound = "We couldn't find that.";
  static const String errorServer =
      'Something went wrong on our side. Please try again shortly.';
  static const String errorGeneric = 'Something went wrong. Please try again.';

  // Common
  static const String retry = 'Try again';
}
