import 'package:flutter/material.dart';
import 'package:flutterapp/core/localization/app_strings.dart';
import 'package:flutterapp/core/util/app_colors.dart';
import 'package:flutterapp/core/util/app_text_style.dart';
import 'package:flutterapp/core/util/formatters.dart';
import 'package:flutterapp/features/products/model/product.dart';

/// Below this many units, stock is called out as running low.
const int lowStockThreshold = 10;

/// Solid ink pill: "-10%". Monochrome so it reads as a label, not an alarm.
class DiscountBadge extends StatelessWidget {
  final double percentage;
  const DiscountBadge(this.percentage, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '-${percentage.round()}%',
        style: AppTextStyles.caption(color: Colors.white, fontSize: 11),
      ),
    );
  }
}

/// White pill with a star and the rating — sits on product photos.
class RatingChip extends StatelessWidget {
  final double rating;
  const RatingChip(this.rating, {super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Rated ${rating.toStringAsFixed(1)} out of 5',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 14, color: AppColors.star),
            const SizedBox(width: 2),
            Text(
              rating.toStringAsFixed(1),
              style: AppTextStyles.caption(color: AppColors.ink, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// Five stars, filled to the nearest whole for [rating].
class StarRow extends StatelessWidget {
  final double rating;
  final double size;
  const StarRow(this.rating, {super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final filled = rating.round();
    return Semantics(
      label: '${rating.toStringAsFixed(1)} out of 5 stars',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 5; i++)
            Icon(
              Icons.star_rounded,
              size: size,
              color: i < filled ? AppColors.star : AppColors.starEmpty,
            ),
        ],
      ),
    );
  }
}

/// Dot + label: green in stock, amber running low, red sold out.
class StockStatus extends StatelessWidget {
  final int stock;
  const StockStatus(this.stock, {super.key});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (stock) {
      <= 0 => (AppStrings.outOfStock, AppColors.error, AppColors.errorSurface),
      < lowStockThreshold => (
        AppStrings.lowStock(stock),
        AppColors.warning,
        AppColors.warningSurface,
      ),
      _ => (
        AppStrings.inStock(stock),
        AppColors.success,
        AppColors.successSurface,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(label, style: AppTextStyles.caption(color: color)),
        ],
      ),
    );
  }
}

/// Selling price, plus the struck-through original when discounted.
class PriceTag extends StatelessWidget {
  final Product product;
  final double fontSize;
  const PriceTag(this.product, {super.key, this.fontSize = 16});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 6,
      children: [
        Text(
          formatPrice(product.price),
          style: AppTextStyles.price(color: AppColors.ink, fontSize: fontSize),
        ),
        if (product.hasDiscount)
          Padding(
            padding: EdgeInsets.only(bottom: fontSize * 0.12),
            child: Text(
              formatPrice(product.originalPrice),
              style: AppTextStyles.caption(
                color: AppColors.textMuted,
                fontSize: fontSize * 0.72,
              ).copyWith(decoration: TextDecoration.lineThrough),
            ),
          ),
      ],
    );
  }
}

/// Green "You save $1.17" under the detail price.
class SavingsLabel extends StatelessWidget {
  final Product product;
  const SavingsLabel(this.product, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.youSave(formatPrice(product.originalPrice - product.price)),
      style: AppTextStyles.caption(color: AppColors.success, fontSize: 13),
    );
  }
}
