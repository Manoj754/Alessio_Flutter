import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterapp/features/products/model/product.dart';
import 'package:flutterapp/features/products/service/product_repository.dart';

/// The full record for one product (`GET /products/{id}`). The detail view
/// paints from the list item it was opened with and swaps to this once it
/// arrives, so the page never opens blank.
final productDetailProvider = FutureProvider.autoDispose.family<Product, int>(
  (ref, id) => ref.watch(productRepositoryProvider).fetchById(id),
);
