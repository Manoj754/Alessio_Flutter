import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterapp/core/config/api_config.dart';
import 'package:flutterapp/core/network/api_client.dart';
import 'package:flutterapp/features/products/model/product.dart';
import 'package:flutterapp/features/products/model/product_page.dart';

/// Reads products from DummyJSON. Errors surface as `ApiException` from the
/// client; this layer only knows paths and JSON shapes.
class ProductRepository {
  final ApiClient _api;
  const ProductRepository(this._api);

  /// One page of the catalogue, or of search results when [query] is given.
  /// Both endpoints page the same way and return the same shape.
  Future<ProductPage> fetchPage({
    required int skip,
    int limit = ApiConfig.pageSize,
    String query = '',
  }) async {
    final q = query.trim();
    final json = await _api.get(
      q.isEmpty ? ApiConfig.products : ApiConfig.productSearch,
      query: {'skip': skip, 'limit': limit, if (q.isNotEmpty) 'q': q},
    );
    return ProductPage.fromJson(json);
  }

  Future<Product> fetchById(int id) async {
    return Product.fromJson(await _api.get(ApiConfig.product(id)));
  }
}

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(ref.watch(apiClientProvider)),
);
