import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterapp/core/localization/app_strings.dart';
import 'package:flutterapp/core/network/api_exception.dart';
import 'package:flutterapp/features/products/model/product.dart';
import 'package:flutterapp/features/products/service/product_repository.dart';

/// Everything the product list view renders once the first page is in.
///
/// The FIRST load's loading/error lives in the surrounding `AsyncValue`
/// (full-screen skeleton / error view). Later pages report through
/// [isLoadingMore] / [loadMoreError] so a failed page shows an inline retry
/// at the bottom instead of wiping the products already on screen.
class ProductListState {
  final List<Product> items;
  final int total;
  final bool isLoadingMore;
  final String? loadMoreError;

  const ProductListState({
    required this.items,
    required this.total,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  bool get hasMore => items.length < total;
  bool get isEmpty => items.isEmpty;

  ProductListState copyWith({
    List<Product>? items,
    int? total,
    bool? isLoadingMore,
    String? Function()? loadMoreError,
  }) {
    return ProductListState(
      items: items ?? this.items,
      total: total ?? this.total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: loadMoreError != null
          ? loadMoreError()
          : this.loadMoreError,
    );
  }
}

/// The product list for one search query (`''` = the whole catalogue). Each
/// query gets its own instance, so its pages, pagination and errors never
/// mix with another query's.
final productListControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ProductListController, ProductListState, String>(
      ProductListController.new,
    );

class ProductListController
    extends AutoDisposeFamilyAsyncNotifier<ProductListState, String> {
  ProductRepository get _repo => ref.read(productRepositoryProvider);

  /// The search query this list belongs to.
  String get query => arg;

  @override
  Future<ProductListState> build(String query) => _firstPage();

  Future<ProductListState> _firstPage() async {
    final page = await _repo.fetchPage(skip: 0, query: query);
    return ProductListState(items: page.products, total: page.total);
  }

  /// Retry after a failed first load — shows the skeleton again.
  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_firstPage);
  }

  /// Pull-to-refresh. Keeps what's on screen if the refresh fails and returns
  /// the user-facing reason (null on success) for the view to show briefly.
  Future<String?> refresh() async {
    try {
      state = AsyncData(await _firstPage());
      return null;
    } on ApiException catch (e) {
      if (!state.hasValue) state = AsyncError(e, StackTrace.current);
      return e.message;
    }
  }

  /// Fetch the next page when the user nears the bottom. Safe to call on
  /// every scroll tick — it no-ops while busy or when everything is loaded.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || state.isLoading) return;
    if (current.isLoadingMore || !current.hasMore) return;
    if (current.loadMoreError != null) return; // wait for an explicit retry

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final page = await _repo.fetchPage(
        skip: current.items.length,
        query: query,
      );
      // Pull-to-refresh may have replaced the list while this page was in
      // flight; append to whatever is current now, skipping duplicates.
      final latest = state.valueOrNull ?? current;
      final seen = latest.items.map((p) => p.id).toSet();
      state = AsyncData(
        latest.copyWith(
          items: [
            ...latest.items,
            ...page.products.where((p) => !seen.contains(p.id)),
          ],
          total: page.total,
          isLoadingMore: false,
          loadMoreError: () => null,
        ),
      );
    } catch (e) {
      final latest = state.valueOrNull ?? current;
      state = AsyncData(
        latest.copyWith(
          isLoadingMore: false,
          loadMoreError: () =>
              e is ApiException ? e.message : AppStrings.loadMoreFailed,
        ),
      );
    }
  }

  /// Retry a failed page from the inline "Try again" at the list's end.
  Future<void> retryLoadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(loadMoreError: () => null));
    await loadMore();
  }
}
