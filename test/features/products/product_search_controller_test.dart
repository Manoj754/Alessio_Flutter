import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterapp/features/products/viewmodel/product_search_controller.dart';

void main() {
  late ProviderContainer container;
  late List<String> applied;

  ProductSearchController search() =>
      container.read(productSearchProvider.notifier);

  /// Just past the debounce window.
  Future<void> pause() =>
      Future<void>.delayed(ProductSearchController.debounce * 1.5);

  setUp(() {
    container = ProviderContainer();
    applied = [];
    container.listen(productSearchProvider, (_, next) => applied.add(next));
  });

  tearDown(() => container.dispose());

  test('typing applies only the final text, once, after a pause', () async {
    for (final text in ['l', 'li', 'lip', 'lipstick']) {
      search().onChanged(text);
    }
    expect(container.read(productSearchProvider), '');
    await pause();
    expect(applied, ['lipstick']);
  });

  test('submit applies immediately and trims', () {
    search().submit('  phone ');
    expect(container.read(productSearchProvider), 'phone');
  });

  test('clear cancels a pending query', () async {
    search().onChanged('watch');
    search().clear();
    await pause();
    expect(container.read(productSearchProvider), '');
    expect(applied, isEmpty);
  });
}
