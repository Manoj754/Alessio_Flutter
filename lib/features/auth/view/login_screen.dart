import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterapp/core/localization/app_strings.dart';
import 'package:flutterapp/core/util/app_colors.dart';
import 'package:flutterapp/core/util/app_text_style.dart';
import 'package:flutterapp/core/util/validators.dart';
import 'package:flutterapp/core/widgets/app_text_field.dart';
import 'package:flutterapp/core/widgets/brand_mark.dart';
import 'package:flutterapp/core/widgets/primary_button.dart';
import 'package:flutterapp/features/auth/viewmodel/login_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref
        .read(loginControllerProvider.notifier)
        .submit(username: _username.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: BrandMark(),
                    ),
                    const SizedBox(height: 32),
                    const _CategoryShowcase(),
                    const SizedBox(height: 32),
                    Text(
                      AppStrings.loginTitle,
                      style: AppTextStyles.headline(color: AppColors.ink),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.loginSubtitle,
                      style: AppTextStyles.body(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 28),
                    AppTextField(
                      label: AppStrings.usernameLabel,
                      hint: AppStrings.usernameHint,
                      icon: Icons.person_outline_rounded,
                      controller: _username,
                      validator: usernameProblem,
                      onChanged: (_) => controller.clearError(),
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      enabled: !status.isLoading,
                    ),
                    const SizedBox(height: 18),
                    AppTextField(
                      label: AppStrings.passwordLabel,
                      hint: AppStrings.passwordHint,
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      controller: _password,
                      validator: passwordProblem,
                      onChanged: (_) => controller.clearError(),
                      onSubmitted: (_) => _submit(),
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      enabled: !status.isLoading,
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: status.hasError
                          ? Padding(
                              padding: const EdgeInsets.only(top: 18),
                              child: _ErrorBanner(status.error.toString()),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      text: AppStrings.logIn,
                      isLoading: status.isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Three soft category tiles — a quick, asset-free picture of "shopping"
/// above the form.
class _CategoryShowcase extends StatelessWidget {
  const _CategoryShowcase();

  @override
  Widget build(BuildContext context) {
    const tiles = [
      (Icons.checkroom_rounded, AppColors.tintPeach, AppColors.tintPeachInk),
      (Icons.headphones_rounded, AppColors.tintSky, AppColors.tintSkyInk),
      (Icons.spa_rounded, AppColors.tintMint, AppColors.tintMintInk),
    ];
    return ExcludeSemantics(
      child: SizedBox(
        height: 132,
        child: Row(
          children: [
            for (final (i, (icon, bg, fg)) in tiles.indexed) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: Container(
                  // Stagger the middle tile for a little rhythm.
                  margin: EdgeInsets.only(
                    top: i == 1 ? 0 : 18,
                    bottom: i == 1 ? 18 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(icon, size: 40, color: fg),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A failed sign-in, shown under the fields.
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: AppColors.errorText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body(
                color: AppColors.errorText,
                fontSize: 13.5,
              ).copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
