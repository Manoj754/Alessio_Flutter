import 'package:flutter/material.dart';
import 'package:flutterapp/core/util/app_colors.dart';
import 'package:flutterapp/core/util/app_text_style.dart';

/// Label above a soft filled input. Focus draws an ink outline; a failing
/// [validator] draws a red one with the message underneath. When
/// [isPassword] is true the text is obscured with a show/hide toggle.
class AppTextField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool isPassword;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  /// Hints for the OS keyboard / password manager (e.g. [AutofillHints.username]).
  /// Wrap the form in an [AutofillGroup] for these to take effect.
  final Iterable<String>? autofillHints;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.autofillHints,
    this.enabled = true,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure = widget.isPassword;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTextStyles.cardTitle(
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          // Re-check as the user types once an error has been shown, so it
          // clears the moment it's fixed.
          autovalidateMode: AutovalidateMode.onUserInteractionIfError,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          enabled: widget.enabled,
          obscureText: _obscure,
          autocorrect: false,
          enableSuggestions: !widget.isPassword,
          style: AppTextStyles.body(color: AppColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTextStyles.body(color: AppColors.hint, fontSize: 15),
            prefixIcon: Icon(widget.icon, color: AppColors.textMuted, size: 22),
            suffixIcon: widget.isPassword
                ? IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                      size: 21,
                    ),
                  )
                : null,
            filled: true,
            fillColor: AppColors.fieldFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: border(Colors.transparent),
            enabledBorder: border(Colors.transparent),
            disabledBorder: border(Colors.transparent),
            focusedBorder: border(AppColors.ink),
            errorBorder: border(AppColors.error),
            focusedErrorBorder: border(AppColors.error),
            errorStyle: AppTextStyles.caption(color: AppColors.errorText),
          ),
        ),
      ],
    );
  }
}
