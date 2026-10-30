import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterapp/core/localization/app_strings.dart';
import 'package:flutterapp/core/network/api_exception.dart';
import 'package:flutterapp/core/router/app_router.dart';
import 'package:flutterapp/core/util/app_colors.dart';
import 'package:flutterapp/core/util/app_text_style.dart';
import 'package:flutterapp/core/widgets/app_network_image.dart';
import 'package:flutterapp/core/widgets/app_snackbar.dart';
import 'package:flutterapp/core/widgets/app_state_view.dart';
import 'package:flutterapp/features/auth/model/auth_user.dart';
import 'package:flutterapp/features/auth/view/account_sheet.dart';
import 'package:flutterapp/features/auth/view/user_avatar.dart';
import 'package:flutterapp/features/auth/viewmodel/auth_controller.dart';
import 'package:flutterapp/features/products/view/product_card.dart';
import 'package:flutterapp/features/products/view/product_search_bar.dart';
import 'package:flutterapp/features/products/viewmodel/product_list_controller.dart';
import 'package:flutterapp/features/products/viewmodel/product_search_controller.dart';
import 'package:go_router/go_router.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _scroll = ScrollController();
  final _searchText = TextEditingController();

  /// Start the next page this far before the end, so it's usually in by the
  /// time the user gets there.
  static const double _prefetchExtent = 800;

  static const double _gutter = 16;
  static const double _gap = 12;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchText.dispose();
    super.dispose();
  }

  /// The list for whatever is being searched right now.
  ProductListController get _list => ref.read(
    productListControllerProvider(ref.read(productSearchProvider)).notifier,
  );

  void _onScroll() {
    if (_scroll.position.extentAfter < _prefetchExtent) _list.loadMore();
  }

  Future<void> _refresh() async {
    final error = await _list.refresh();
    if (error != null && mounted) AppSnackbar.show(context, error);
  }

  void _clearSearch() {
    _searchText.clear();
    ref.read(productSearchProvider.notifier).clear();
  }

  /// Warm the image cache with each new page's thumbnails (~5–10 KB each) as
  /// soon as the page arrives, so cards scrolled into view already have
  /// their photo instead of a placeholder.
  void _prefetchThumbnails(ProductListState? prev, ProductListState next) {
    final from = prev == null || next.items.length < prev.items.length
        ? 0
        : prev.items.length;
    for (final p in next.items.skip(from)) {
      AppNetworkImage.prefetch(context, p.thumbnail);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(productSearchProvider);
    final listProvider = productListControllerProvider(query);

    // New query → start at the top of its results.
    ref.listen(productSearchProvider, (_, _) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
    });
    ref.listen(listProvider, (prev, next) {
      final data = next.valueOrNull;
      if (data != null) _prefetchThumbnails(prev?.valueOrNull, data);
    });

    final async = ref.watch(listProvider);
    final controller = ref.read(listProvider.notifier);
    final user = ref.watch(authControllerProvider.select((s) => s.user));

    // Square photo + fixed text block, scaled with the user's text size so
    // cards never clip.
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = (width - _gutter * 2 - _gap) / 2;
    final cardHeight =
        cardWidth +
        MediaQuery.textScalerOf(context).scale(productCardInfoHeight);
    final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: _gap,
      crossAxisSpacing: _gap,
      mainAxisExtent: cardHeight,
    );
    const gridPadding = EdgeInsets.symmetric(horizontal: _gutter);

    // Greeting row: top padding + the taller of the two text lines and the
    // 46px avatar + a gap above the search bar. Scales with text size.
    final headerHeight =
        12 + MediaQuery.textScalerOf(context).scale(58).clamp(46.0, 140.0) + 8;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _refresh,
            // Header and search bar stay put across loading / error / empty
            // so the screen never jumps — only the body below them changes.
            child: CustomScrollView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                // Scrolling down tucks the greeting away and keeps the search
                // bar pinned; any scroll UP brings the greeting (and the
                // profile button) straight back, so logging out never means
                // scrolling all the way to the top.
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  snap: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: AppColors.background,
                  surfaceTintColor: Colors.transparent,
                  scrolledUnderElevation: 0,
                  elevation: 0,
                  toolbarHeight: 0,
                  collapsedHeight: 0,
                  expandedHeight: headerHeight + searchBarSlotHeight,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: _Header(
                          user: user,
                          onAvatarTap: () => AccountSheet.show(
                            context,
                            user: user,
                            onLogout: () => ref
                                .read(authControllerProvider.notifier)
                                .logout(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(searchBarSlotHeight),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: ProductSearchBar(
                        controller: _searchText,
                        onChanged: ref
                            .read(productSearchProvider.notifier)
                            .onChanged,
                        onSubmitted: ref
                            .read(productSearchProvider.notifier)
                            .submit,
                        onClear: _clearSearch,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  sliver: SliverToBoxAdapter(
                    // Reserve the line while the count loads so nothing
                    // shifts.
                    child: SizedBox(
                      height: 18,
                      child: switch (async.valueOrNull?.total) {
                        null => null,
                        final total => Text(
                          query.isEmpty
                              ? AppStrings.productCount(total)
                              : AppStrings.searchResults(total, query),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      },
                    ),
                  ),
                ),
                ...async.when(
                  skipLoadingOnRefresh: true,
                  loading: () => [
                    SliverPadding(
                      padding: gridPadding,
                      sliver: SliverGrid.builder(
                        gridDelegate: gridDelegate,
                        itemCount: 6,
                        itemBuilder: (_, _) => const ProductCardSkeleton(),
                      ),
                    ),
                  ],
                  error: (e, _) => [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _ErrorState(error: e, onRetry: controller.retry),
                    ),
                  ],
                  data: (data) => data.isEmpty
                      ? [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: query.isEmpty
                                ? const AppStateView(
                                    icon: Icons.inventory_2_outlined,
                                    title: AppStrings.productsEmptyTitle,
                                    message: AppStrings.productsEmptyMessage,
                                  )
                                : AppStateView(
                                    icon: Icons.search_off_rounded,
                                    title: AppStrings.noResultsTitle(query),
                                    message: AppStrings.noResultsMessage,
                                    actionLabel: AppStrings.clearSearch,
                                    actionIcon: Icons.close_rounded,
                                    onAction: _clearSearch,
                                  ),
                          ),
                        ]
                      : [
                          SliverPadding(
                            padding: gridPadding,
                            sliver: SliverGrid.builder(
                              gridDelegate: gridDelegate,
                              itemCount: data.items.length,
                              itemBuilder: (context, i) {
                                final product = data.items[i];
                                return ProductCard(
                                  product: product,
                                  onTap: () => context.push(
                                    AppRouter.productDetail(product.id),
                                    extra: product,
                                  ),
                                );
                              },
                            ),
                          ),
                          SliverSafeArea(
                            top: false,
                            sliver: SliverToBoxAdapter(
                              child: _ListFooter(
                                state: data,
                                onRetry: controller.retryLoadMore,
                              ),
                            ),
                          ),
                        ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AuthUser? user;
  final VoidCallback onAvatarTap;

  const _Header({required this.user, required this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    final name = user?.firstName;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name == null || name.isEmpty
                    ? AppStrings.helloFallback
                    : AppStrings.hello(name),
                style: AppTextStyles.body(color: AppColors.textSecondary),
              ),
              Text(
                AppStrings.productsTitle,
                style: AppTextStyles.headline(color: AppColors.ink),
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: AppStrings.account,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onAvatarTap,
            child: UserAvatar(user: user, size: 46),
          ),
        ),
      ],
    );
  }
}

/// First-load failure. Offline gets its own icon so the cause is obvious.
class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final e = error;
    final offline =
        e is ApiException &&
        (e.type == ApiErrorType.network || e.type == ApiErrorType.timeout);
    return AppStateView(
      icon: offline ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
      title: AppStrings.productsErrorTitle,
      message: e is ApiException ? e.message : AppStrings.errorGeneric,
      actionLabel: AppStrings.retry,
      onAction: onRetry,
      tint: AppColors.errorSurface,
      iconColor: AppColors.errorText,
    );
  }
}

/// The row after the last product: a spinner while the next page loads, an
/// inline retry if it failed, or a quiet end marker.
class _ListFooter extends StatelessWidget {
  final ProductListState state;
  final VoidCallback onRetry;

  const _ListFooter({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (state.loadMoreError != null) {
      child = Column(
        children: [
          Text(
            state.loadMoreError!,
            textAlign: TextAlign.center,
            style: AppTextStyles.body(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(AppStrings.retry),
          ),
        ],
      );
    } else if (state.hasMore) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
          const SizedBox(width: 10),
          Text(
            AppStrings.loadingMore,
            style: AppTextStyles.caption(color: AppColors.textSecondary),
          ),
        ],
      );
    } else {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            AppStrings.endOfList,
            style: AppTextStyles.caption(color: AppColors.textMuted),
          ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(child: child),
    );
  }
}
