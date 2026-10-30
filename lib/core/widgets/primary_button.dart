import 'package:flutter/material.dart';
import 'package:flutterapp/core/util/app_colors.dart';
import 'package:flutterapp/core/util/app_text_style.dart';

/// The app's main call-to-action: solid ink, 16px corners. Shows a spinner in
/// place of the label while [isLoading], and keeps its colour so it doesn't
/// flash grey on tap. [outlined] gives the quieter secondary version.
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;
  final IconData? icon;
  final Color color;
  final double height;
  final double width;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.outlined = false,
    this.icon,
    this.color = AppColors.primaryButton,
    this.height = 56,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final fg = outlined ? color : Colors.white;
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: outlined ? AppColors.surface : color,
          disabledBackgroundColor: outlined
              ? AppColors.surface
              : (isLoading ? color : AppColors.disabled),
          foregroundColor: fg,
          overlayColor: fg.withValues(alpha: 0.1),
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: outlined
                ? const BorderSide(color: AppColors.border)
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: fg),
                    const SizedBox(width: 10),
                  ],
                  Text(text, style: AppTextStyles.label(color: fg)),
                ],
              ),
      ),
    );
  }
}
