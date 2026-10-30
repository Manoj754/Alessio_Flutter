import 'package:flutter/material.dart';
import 'package:flutterapp/core/util/app_colors.dart';
import 'package:flutterapp/core/util/app_text_style.dart';
import 'package:flutterapp/core/widgets/app_network_image.dart';

/// Full-bleed, swipeable product photos with page dots and a "1 / 3" counter.
///
/// Built to open instantly: the first page shows the list [thumbnail] (already
/// in memory) until the full-size photo lands, it carries the Hero from the
/// list card, and every other photo starts downloading as soon as the page
/// opens so swiping never waits.
class ProductGallery extends StatefulWidget {
  final int productId;
  final List<String> images;
  final String thumbnail;

  /// Extra space above the photos for the status bar / floating back button.
  final double topInset;

  const ProductGallery({
    super.key,
    required this.productId,
    required this.images,
    required this.thumbnail,
    this.topInset = 0,
  });

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  int _page = 0;
  bool _prefetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefetched) return;
    _prefetched = true;
    for (final url in widget.images) {
      AppNetworkImage.prefetch(context, url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final height =
        widget.topInset +
        MediaQuery.sizeOf(context).width.clamp(0.0, 460.0) * 0.9;
    return Container(
      height: height,
      color: AppColors.imageTile,
      padding: EdgeInsets.only(top: widget.topInset),
      child: Stack(
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final image = AppNetworkImage(
                url: images[i],
                placeholderUrl: i == 0 ? widget.thumbnail : null,
              );
              // Padding stays OUTSIDE the Hero (as on the list card): inside,
              // it would apply to the flying image too and shrink it the
              // instant the transition starts.
              return Padding(
                padding: const EdgeInsets.fromLTRB(40, 16, 40, 44),
                child: i == 0
                    ? Hero(tag: 'product-${widget.productId}', child: image)
                    : image,
              );
            },
          ),
          if (images.length > 1) ...[
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < images.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _page ? AppColors.ink : AppColors.disabled,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_page + 1} / ${images.length}',
                  style: AppTextStyles.caption(
                    color: AppColors.ink,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
