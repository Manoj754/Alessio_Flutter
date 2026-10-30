import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The active search query (`''` = no search). The list watches
/// `productListControllerProvider(query)`, so changing this swaps results.
///
/// Typing is debounced: the query only changes once the user pauses, so
/// "lipstick" makes one request, not eight.
final productSearchProvider =
    AutoDisposeNotifierProvider<ProductSearchController, String>(
      ProductSearchController.new,
    );

class ProductSearchController extends AutoDisposeNotifier<String> {
  static const Duration debounce = Duration(milliseconds: 350);

  Timer? _timer;

  @override
  String build() {
    ref.onDispose(() => _timer?.cancel());
    return '';
  }

  /// Every keystroke. Applies [text] after a pause in typing.
  void onChanged(String text) {
    _timer?.cancel();
    final q = text.trim();
    if (q == state) return;
    _timer = Timer(debounce, () => state = q);
  }

  /// The keyboard's search button — apply right away.
  void submit(String text) {
    _timer?.cancel();
    state = text.trim();
  }

  void clear() {
    _timer?.cancel();
    state = '';
  }
}
