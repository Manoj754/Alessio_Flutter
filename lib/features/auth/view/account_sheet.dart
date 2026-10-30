import 'package:flutter/material.dart';
import 'package:flutterapp/core/localization/app_strings.dart';
import 'package:flutterapp/core/util/app_colors.dart';
import 'package:flutterapp/core/util/app_text_style.dart';
import 'package:flutterapp/core/widgets/primary_button.dart';
import 'package:flutterapp/features/auth/model/auth_user.dart';
import 'package:flutterapp/features/auth/view/user_avatar.dart';

/// Bottom sheet opened from the avatar: who's signed in, and log out.
class AccountSheet extends StatelessWidget {
  final AuthUser? user;
  final VoidCallback onLogout;

  const AccountSheet({super.key, required this.user, required this.onLogout});

  static Future<void> show(
    BuildContext context, {
    required AuthUser? user,
    required VoidCallback onLogout,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (_) => AccountSheet(user: user, onLogout: onLogout),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = user;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(user: u, size: 72),
            const SizedBox(height: 14),
            Text(
              u?.fullName ?? AppStrings.account,
              textAlign: TextAlign.center,
              style: AppTextStyles.title(color: AppColors.ink, fontSize: 20),
            ),
            if (u != null) ...[
              const SizedBox(height: 4),
              Text(
                u.email,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                '@${u.username}',
                style: AppTextStyles.caption(color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: 28),
            PrimaryButton(
              text: AppStrings.logOut,
              icon: Icons.logout_rounded,
              outlined: true,
              color: AppColors.errorText,
              onPressed: () {
                Navigator.of(context).pop();
                onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
