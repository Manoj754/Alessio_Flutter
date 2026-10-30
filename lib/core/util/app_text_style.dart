import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The app's type scale, all Plus Jakarta Sans — a geometric sans that reads
/// cleanly at small sizes and has confident heavy weights for titles and
/// prices. Colour is always passed in so one style serves every surface.
class AppTextStyles {
  AppTextStyles._();

  /// Resolved GoogleFonts styles, keyed by everything EXCEPT colour. Resolving
  /// a GoogleFonts style is relatively expensive and these helpers run inside
  /// build methods, so the font part is cached once and the colour is applied
  /// with a cheap copyWith.
  static final Map<String, TextStyle> _cache = {};

  static TextStyle _resolve(String key, TextStyle Function() build) =>
      _cache[key] ??= build();

  // Screen titles ("Discover", "Welcome back").
  static TextStyle headline({required Color color, double fontSize = 30}) {
    return _resolve(
      'headline:$fontSize',
      () => GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.8,
      ),
    ).copyWith(color: color);
  }

  // Section and sheet titles ("Reviews", product name on detail).
  static TextStyle title({required Color color, double fontSize = 18}) {
    return _resolve(
      'title:$fontSize',
      () => GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.3,
      ),
    ).copyWith(color: color);
  }

  // The name of ONE item inside a card or row.
  static TextStyle cardTitle({required Color color, double fontSize = 14}) {
    return _resolve(
      'cardTitle:$fontSize',
      () => GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    ).copyWith(color: color);
  }

  // Prices — heavy with tabular figures so stacked prices line up.
  static TextStyle price({required Color color, double fontSize = 16}) {
    return _resolve(
      'price:$fontSize',
      () => GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    ).copyWith(color: color);
  }

  // Standard body/reading copy.
  static TextStyle body({required Color color, double fontSize = 14}) {
    return _resolve(
      'body:$fontSize',
      () => GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        height: 1.55,
      ),
    ).copyWith(color: color);
  }

  // Small supporting text: brand, counts, badges.
  static TextStyle caption({required Color color, double fontSize = 12}) {
    return _resolve(
      'caption:$fontSize',
      () => GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    ).copyWith(color: color);
  }

  // Button and inline CTA text.
  static TextStyle label({required Color color, double fontSize = 16}) {
    return _resolve(
      'label:$fontSize',
      () => GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
      ),
    ).copyWith(color: color);
  }
}
