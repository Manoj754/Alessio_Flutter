import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterapp/core/localization/app_strings.dart';
import 'package:flutterapp/core/util/app_colors.dart';
import 'package:flutterapp/core/util/app_text_style.dart';
import 'package:flutterapp/core/util/formatters.dart';
import 'package:flutterapp/core/widgets/app_icon_button.dart';
import 'package:flutterapp/core/widgets/app_state_view.dart';
import 'package:flutterapp/core/widgets/skeleton_loader.dart';
import 'package:flutterapp/features/products/model/product.dart';
import 'package:flutterapp/features/products/model/product_review.dart';
import 'package:flutterapp/features/products/view/product_badges.dart';
import 'package:flutterapp/features/products/view/product_gallery.dart';
import 'package:flutterapp/features/products/viewmodel/product_detail_controller.dart';
import 'package:go_router/go_router.dart';

class ProductDetailScreen extends ConsumerWidget {
  final int productId;

  /// The list item that was tapped, painted immediately while the full record
  /// loads. Null on a deep link.
  final Product? initial;

  const ProductDetailScreen({super.key, required this.productId, this.initial});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productDetailProvider(productId));
    final product = async.valueOrNull ?? initial;
    final top = MediaQuery.paddingOf(context).top;

    final Widget body;
    if (product != null) {
      body = _Content(product: product, topInset: top + 20);
    } else if (async.hasError) {
      body = AppStateView(
        icon: Icons.error_outline_rounded,
        title: AppStrings.productErrorTitle,
        message: async.error.toString(),
        actionLabel: AppStrings.retry,
        onAction: () => ref.invalidate(productDetailProvider(productId)),
        tint: AppColors.errorSurface,
        iconColor: AppColors.errorText,
      );
    } else {
      body = _DetailSkeleton(topInset: top + 20);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Stack(
          children: [
            Positioned.fill(child: body),
            // Floats over the photo and stays put while the page scrolls.
            Positioned(
              top: top + 8,
              left: 16,
              child: AppIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => context.pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final Product product;
  final double topInset;
  const _Content({required this.product, required this.topInset});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ProductGallery(
          productId: product.id,
          images: product.gallery,
          thumbnail: product.thumbnail,
          topInset: topInset,
        ),
        // The white sheet's rounded top sits on the photo's grey, so it reads
        // as a card pulled up over the image.
        ColoredBox(
          color: AppColors.imageTile,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(20, 24, 20, 32 + bottom),
            // Readable line length on tablets; full width on phones.
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Summary(product: product),
                  const _Divider(),
                  _SectionTitle(AppStrings.description),
                  const SizedBox(height: 8),
                  _ExpandableText(product.description),
                  const _Divider(),
                  _SectionTitle(AppStrings.details),
                  const SizedBox(height: 12),
                  _DetailsList(product: product),
                  const _Divider(),
                  _Reviews(product: product),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Category, brand, title, rating, price and stock — everything a shopper
/// scans first.
class _Summary extends StatelessWidget {
  final Product product;
  const _Summary({required this.product});

  @override
  Widget build(BuildContext context) {
    final category = product.category.replaceAll('-', ' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wrap, not Row: long category/brand names or large text move to a
        // second line instead of overflowing.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Chip(
              category.isEmpty
                  ? ''
                  : category[0].toUpperCase() + category.substring(1),
            ),
            if (product.brand != null) _Chip(product.brand!),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          product.title,
          style: AppTextStyles.title(color: AppColors.ink, fontSize: 24),
        ),
        const SizedBox(height: 10),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            StarRow(product.rating),
            Text(
              product.rating.toStringAsFixed(1),
              style: AppTextStyles.cardTitle(
                color: AppColors.ink,
                fontSize: 13,
              ),
            ),
            if (product.reviews.isNotEmpty)
              Text(
                '·  ${AppStrings.reviewCount(product.reviews.length)}',
                style: AppTextStyles.caption(color: AppColors.textSecondary),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: PriceTag(product, fontSize: 28)),
            if (product.hasDiscount) DiscountBadge(product.discountPercentage),
          ],
        ),
        if (product.hasDiscount) ...[
          const SizedBox(height: 4),
          SavingsLabel(product),
        ],
        const SizedBox(height: 14),
        StockStatus(product.stock),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption(color: AppColors.textSecondary),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.title(color: AppColors.ink, fontSize: 17),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 22),
    child: Divider(height: 1, color: AppColors.divider),
  );
}

/// Long descriptions collapse to four lines with a "Read more" toggle; short
/// ones show in full with no toggle.
class _ExpandableText extends StatefulWidget {
  final String text;
  const _ExpandableText(this.text);

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  static const _collapsedLines = 4;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.body(color: AppColors.textSecondary);
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _collapsedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: Text(
                widget.text,
                style: style,
                maxLines: _expanded ? null : _collapsedLines,
                overflow: _expanded ? null : TextOverflow.ellipsis,
              ),
            ),
            if (overflows)
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 40),
                ),
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? AppStrings.showLess : AppStrings.readMore,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DetailsList extends StatelessWidget {
  final Product product;
  const _DetailsList({required this.product});

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String, String)>[
      if (product.shippingInformation.isNotEmpty)
        (
          Icons.local_shipping_outlined,
          AppStrings.shipping,
          product.shippingInformation,
        ),
      if (product.warrantyInformation.isNotEmpty)
        (
          Icons.verified_user_outlined,
          AppStrings.warranty,
          product.warrantyInformation,
        ),
      if (product.returnPolicy.isNotEmpty)
        (Icons.replay_rounded, AppStrings.returns, product.returnPolicy),
    ];
    return Column(
      children: [
        for (final (i, (icon, label, value)) in rows.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.fieldFill,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 21, color: AppColors.ink),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.caption(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: AppTextStyles.cardTitle(color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Reviews extends StatelessWidget {
  final Product product;
  const _Reviews({required this.product});

  @override
  Widget build(BuildContext context) {
    final reviews = product.reviews;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(AppStrings.reviews),
        const SizedBox(height: 14),
        if (reviews.isEmpty)
          Text(
            AppStrings.noReviews,
            style: AppTextStyles.body(color: AppColors.textSecondary),
          )
        else ...[
          // Average from the reviews shown, so the summary matches the list.
          _RatingSummary(
            average:
                reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                reviews.length,
            count: reviews.length,
          ),
          const SizedBox(height: 14),
          for (final r in reviews) _ReviewTile(review: r),
        ],
      ],
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final double average;
  final int count;
  const _RatingSummary({required this.average, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            average.toStringAsFixed(1),
            style: AppTextStyles.headline(color: AppColors.ink, fontSize: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StarRow(average, size: 18),
                const SizedBox(height: 4),
                Text(
                  AppStrings.basedOnReviews(count),
                  style: AppTextStyles.caption(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ProductReview review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final date = review.date;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.imageTile,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initialsOf(review.reviewerName),
                  style: AppTextStyles.cardTitle(
                    color: AppColors.ink,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: AppTextStyles.cardTitle(color: AppColors.ink),
                    ),
                    if (date != null)
                      Text(
                        formatShortDate(date),
                        style: AppTextStyles.caption(
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              StarRow(review.rating.toDouble(), size: 14),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.comment,
            style: AppTextStyles.body(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Deep-link load (no list item to paint from): ghost of the real layout.
class _DetailSkeleton extends StatelessWidget {
  final double topInset;
  const _DetailSkeleton({required this.topInset});

  @override
  Widget build(BuildContext context) {
    final photo =
        topInset + MediaQuery.sizeOf(context).width.clamp(0.0, 460.0) * 0.9;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(height: photo, radius: 0),
        const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 90, height: 26, radius: 13),
              SizedBox(height: 16),
              SkeletonBox(width: 260, height: 24),
              SizedBox(height: 12),
              SkeletonBox(width: 140, height: 16),
              SizedBox(height: 20),
              SkeletonBox(width: 120, height: 30),
            ],
          ),
        ),
      ],
    );
  }
}
