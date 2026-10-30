import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterapp/core/network/api_exception.dart';
import 'package:flutterapp/features/products/model/product.dart';
import 'package:flutterapp/features/products/model/product_page.dart';
import 'package:flutterapp/features/products/service/product_repository.dart';
import 'package:flutterapp/features/products/viewmodel/product_list_controller.dart';

/// Serves [total] fake products in pages; can be told to fail the next call.
class _FakeRepo implements ProductRepository {
  final int total;
  bool failNext = false;

  /// Every (query, skip) requested, to check what reached the repository.
  final calls = <(String, int)>[];
  _FakeRepo(this.total);

  @override
  Future<ProductPage> fetchPage({
    required int skip,
    int limit = 20,
    String query = '',
  }) async {
    calls.add((query, skip));
    if (failNext) {
      failNext = false;
      throw const ApiException.network();
    }
    final end = (skip + limit).clamp(0, total);
    return ProductPage(
      products: [for (var i = skip; i < end; i++) _product(i + 1)],
      total: total,
      skip: skip,
      limit: limit,
    );
  }

  @override
  Future<Product> fetchById(int id) async => _product(id);
}

Product _product(int id) =>
    Product.fromJson({'id': id, 'title': 'Product $id', 'price': 10});

/// The unfiltered list (no search query).
final catalogue = productListControllerProvider('');

void main() {
  late _FakeRepo repo;
  late ProviderContainer container;

  ProductListState state() => container.read(catalogue).requireValue;

  setUp(() {
    repo = _FakeRepo(45);
    container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(repo)],
    );
    // Keep the auto-dispose provider alive for the whole test.
    container.listen(catalogue, (_, _) {});
  });

  tearDown(() => container.dispose());

  test('loads the first page', () async {
    await container.read(catalogue.future);
    expect(state().items.length, 20);
    expect(state().hasMore, isTrue);
  });

  test('loadMore appends pages until total is reached', () async {
    await container.read(catalogue.future);
    final c = container.read(catalogue.notifier);
    await c.loadMore();
    await c.loadMore();
    expect(state().items.length, 45);
    expect(state().hasMore, isFalse);
    expect(state().items.map((p) => p.id).toSet().length, 45);
  });

  test('a failed page keeps loaded items and can be retried', () async {
    await container.read(catalogue.future);
    final c = container.read(catalogue.notifier);
    repo.failNext = true;
    await c.loadMore();
    expect(state().items.length, 20);
    expect(state().loadMoreError, isNotNull);

    await c.retryLoadMore();
    expect(state().items.length, 40);
    expect(state().loadMoreError, isNull);
  });

  test('a failed refresh keeps the list and reports why', () async {
    await container.read(catalogue.future);
    final c = container.read(catalogue.notifier);
    repo.failNext = true;
    final error = await c.refresh();
    expect(error, isNotNull);
    expect(state().items.length, 20);
  });

  test('empty catalogue gives an empty state, not an error', () async {
    repo = _FakeRepo(0);
    container.dispose();
    container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(repo)],
    );
    container.listen(catalogue, (_, _) {});
    await container.read(catalogue.future);
    expect(state().isEmpty, isTrue);
    expect(state().hasMore, isFalse);
  });

  test('a search query reaches the repository on every page', () async {
    final search = productListControllerProvider('phone');
    container.listen(search, (_, _) {});
    await container.read(search.future);
    await container.read(search.notifier).loadMore();
    expect(repo.calls.where((c) => c.$1 == 'phone').map((c) => c.$2), [0, 20]);
  });
}
