import 'package:flutter/material.dart';
import 'package:flutterapp/core/localization/app_strings.dart';
import 'package:flutterapp/core/util/app_colors.dart';
import 'package:flutterapp/core/util/app_text_style.dart';

/// Rounded white search field with a clear button that appears once there's
/// text. Purely presentational — the screen wires it to the search viewmodel.
class ProductSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const ProductSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: 1.5),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      style: AppTextStyles.body(color: AppColors.ink, fontSize: 15),
      decoration: InputDecoration(
        hintText: AppStrings.searchHint,
        hintStyle: AppTextStyles.body(color: AppColors.hint, fontSize: 15),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textMuted,
          size: 22,
        ),
        // Rebuilds only the clear button as the text changes.
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: AppStrings.clearSearch,
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: border(Colors.transparent),
        enabledBorder: border(Colors.transparent),
        focusedBorder: border(AppColors.ink),
      ),
    );
  }
}

/// Vertical space the search bar takes in the header, padding included.
const double searchBarSlotHeight = 72;
