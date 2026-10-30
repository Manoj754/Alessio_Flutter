import 'package:flutterapp/features/products/model/product.dart';

/// One page of `GET /products` — DummyJSON paginates with `skip` + `limit`
/// and reports the overall `total`.
class ProductPage {
  final List<Product> products;
  final int total;
  final int skip;
  final int limit;

  const ProductPage({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory ProductPage.fromJson(Map<String, dynamic> json) => ProductPage(
    products: (json['products'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList(),
    total: (json['total'] as num?)?.toInt() ?? 0,
    skip: (json['skip'] as num?)?.toInt() ?? 0,
    limit: (json['limit'] as num?)?.toInt() ?? 0,
  );
}
