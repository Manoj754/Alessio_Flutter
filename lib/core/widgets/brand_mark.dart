import 'package:flutter/material.dart';
import 'package:flutterapp/core/localization/app_strings.dart';
import 'package:flutterapp/core/util/app_colors.dart';
import 'package:flutterapp/core/util/app_text_style.dart';

/// The app's logo: an ink tile with a bag glyph, optionally with the name
/// beside it.
class BrandMark extends StatelessWidget {
  final double size;
  final bool showName;

  const BrandMark({super.key, this.size = 40, this.showName = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(size * 0.32),
          ),
          child: Icon(
            Icons.shopping_bag_rounded,
            size: size * 0.52,
            color: Colors.white,
          ),
        ),
        if (showName) ...[
          SizedBox(width: size * 0.3),
          Text(
            AppStrings.appName,
            style: AppTextStyles.title(
              color: AppColors.ink,
              fontSize: size * 0.48,
            ),
          ),
        ],
      ],
    );
  }
}
