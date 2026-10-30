import 'package:flutter/material.dart';
import 'package:flutterapp/core/util/app_colors.dart';
import 'package:flutterapp/core/util/app_text_style.dart';
import 'package:flutterapp/core/widgets/app_network_image.dart';
import 'package:flutterapp/core/widgets/skeleton_loader.dart';
import 'package:flutterapp/features/products/model/product.dart';
import 'package:flutterapp/features/products/view/product_badges.dart';

/// Height of a card's text block under the square photo, before text
/// scaling. The grid sizes its cells from this so cards never clip.
const double productCardInfoHeight = 100;

/// One grid tile: square photo on a grey tile with the discount and rating
/// floating on it, then brand, a two-line title and the price.
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Start fetching the detail photo on finger-down, ~100ms before the
        // tap completes, so it's usually ready when the page opens.
        onTapDown: (_) =>
            AppNetworkImage.prefetch(context, product.gallery.first),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: AppColors.imageTile,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Hero(
                          tag: 'product-${product.id}',
                          child: AppNetworkImage(url: product.thumbnail),
                        ),
                      ),
                    ),
                    if (product.hasDiscount)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: DiscountBadge(product.discountPercentage),
                      ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: RatingChip(product.rating),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.brand ?? _capitalize(product.category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle(color: AppColors.ink),
                    ),
                    const Spacer(),
                    PriceTag(product),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _capitalize(String s) => s.isEmpty
    ? s
    : '${s[0].toUpperCase()}${s.substring(1).replaceAll('-', ' ')}';

/// Ghost version of [ProductCard] for the first load.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: SkeletonBox(height: double.infinity, radius: 0),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 60, height: 10, radius: 5),
                SizedBox(height: 8),
                SkeletonBox(width: 130, height: 13, radius: 6),
                SizedBox(height: 14),
                SkeletonBox(width: 70, height: 15, radius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
