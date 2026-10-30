import 'package:flutter/material.dart';
import 'package:flutterapp/core/util/app_colors.dart';
import 'package:flutterapp/core/widgets/brand_mark.dart';

/// Shown while the stored session is checked. The router moves on by itself
/// once [AuthStatus] is known — this screen has no navigation logic.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(child: BrandMark(size: 56)),
    );
  }
}
