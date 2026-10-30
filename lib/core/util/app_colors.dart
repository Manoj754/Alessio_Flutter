import 'package:flutter/material.dart';

/// Every colour the app uses. Widgets reference these tokens — never a raw
/// `Color(0x…)` — so a re-theme only touches this file.
///
/// A neutral, product-first palette: near-black ink for text, prices and
/// actions, cool light greys so product photos (mostly on white) stand out,
/// and green only to say "you save".
class AppColors {
  AppColors._();

  // Ink & actions
  static const Color ink = Color(0xff0F1115);
  static const Color primaryButton = ink;

  // Surfaces
  static const Color background = Color(0xffF5F6F8);
  static const Color surface = Colors.white;
  // Behind product photos: a touch darker than the page so white-background
  // product shots read as objects, not holes.
  static const Color imageTile = Color(0xffEEF0F3);
  static const Color fieldFill = Color(0xffF1F2F5);
  static const Color skeleton = Color(0xffE6E8EC);

  // Text (each checked for ≥4.5:1 on white and on [background])
  static const Color textPrimary = ink;
  static const Color textSecondary = Color(0xff5B6170);
  static const Color textMuted = Color(0xff737885);
  static const Color hint = Color(0xff8B909C);

  // Lines
  static const Color border = Color(0xffE6E8EC);
  static const Color divider = Color(0xffEDEEF1);
  static const Color disabled = Color(0xffC7CAD1);

  // Status
  static const Color success = Color(0xff15803D);
  static const Color successSurface = Color(0xffE7F6EC);
  static const Color warning = Color(0xffB45309);
  static const Color warningSurface = Color(0xffFDF1E3);
  static const Color error = Color(0xffDC2626);
  static const Color errorSurface = Color(0xffFDECEC);
  static const Color errorText = Color(0xffB91C1C);

  // Rating star (icon only — never text).
  static const Color star = Color(0xffFFB020);
  static const Color starEmpty = Color(0xffDDE0E5);

  // Soft category tints for the login showcase tiles.
  static const Color tintPeach = Color(0xffFFE9DF);
  static const Color tintPeachInk = Color(0xffC2410C);
  static const Color tintSky = Color(0xffE2EEFF);
  static const Color tintSkyInk = Color(0xff1D4ED8);
  static const Color tintMint = Color(0xffE3F5EA);
  static const Color tintMintInk = Color(0xff15803D);
}
