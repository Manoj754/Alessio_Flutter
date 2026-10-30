import 'package:flutter/material.dart';
import 'package:flutterapp/core/util/app_colors.dart';
import 'package:flutterapp/core/util/app_text_style.dart';
import 'package:flutterapp/core/util/formatters.dart';
import 'package:flutterapp/features/auth/model/auth_user.dart';

/// The signed-in user as white initials on an ink disc ("EJ"), or a person
/// glyph when the profile isn't known (e.g. a session restored offline).
///
/// DummyJSON's `image` is a generated pattern, not a face, so it's not used.
class UserAvatar extends StatelessWidget {
  final AuthUser? user;
  final double size;

  const UserAvatar({super.key, required this.user, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final u = user;
    final initials = u == null ? '' : initialsOf(u.fullName);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.ink,
        shape: BoxShape.circle,
      ),
      child: initials.isEmpty
          ? Icon(Icons.person_rounded, color: Colors.white, size: size * 0.5)
          : Text(
              initials,
              style: AppTextStyles.label(
                color: Colors.white,
                fontSize: size * 0.36,
              ),
            ),
    );
  }
}
