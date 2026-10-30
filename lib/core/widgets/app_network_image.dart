import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutterapp/core/util/app_colors.dart';

/// Remote image with disk + memory caching, tuned so it never flickers:
///
/// * Already in memory (seen before, or [prefetch]ed) → drawn on the very
///   first frame, no placeholder and no animation.
/// * With a [placeholderUrl] (the list thumbnail, usually already in memory)
///   → the thumbnail shows until the full image has decoded, then the two
///   swap in a single frame. No cross-fade: product photos have transparent
///   backgrounds, so fading one out while the other fades in made the
///   product visibly blink.
/// * Otherwise → a small spinner, then a short fade-in.
/// * A failed load falls back to the placeholder if there is one, else a
///   quiet icon — never Flutter's red error box.
class AppNetworkImage extends StatelessWidget {
  final String url;
  final String? placeholderUrl;
  final BoxFit fit;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.placeholderUrl,
    this.fit = BoxFit.contain,
  });

  /// Start downloading [url] into the cache before it's on screen (e.g. the
  /// detail image as soon as a product is tapped). Safe to call repeatedly —
  /// a cached image resolves immediately.
  static void prefetch(BuildContext context, String url) {
    if (url.isEmpty) return;
    precacheImage(
      CachedNetworkImageProvider(url),
      context,
      onError: (_, _) {}, // a failed prefetch just means a normal load later
    );
  }

  @override
  Widget build(BuildContext context) {
    final placeholderUrl = this.placeholderUrl;
    final Widget placeholder = placeholderUrl != null && placeholderUrl != url
        ? Image(
            image: CachedNetworkImageProvider(placeholderUrl),
            fit: fit,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const _Loading(),
          )
        : const _Loading();
    final hasImagePlaceholder = placeholder is Image;

    return Image(
      image: CachedNetworkImageProvider(url),
      fit: fit,
      // Keep the current picture while a new one loads instead of going
      // blank for a frame.
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        final loaded = frame != null;
        if (hasImagePlaceholder) return loaded ? child : placeholder;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: loaded
              ? KeyedSubtree(key: const ValueKey('image'), child: child)
              : KeyedSubtree(
                  key: const ValueKey('loading'),
                  child: placeholder,
                ),
        );
      },
      errorBuilder: (context, _, _) => hasImagePlaceholder
          ? placeholder
          : const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.textMuted,
              ),
            ),
    );
  }
}

/// A small, quiet spinner on the photo's own background — no grey box, so
/// nothing square shows behind a product while it loads.
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Center(
    child: SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppColors.disabled,
      ),
    ),
  );
}
