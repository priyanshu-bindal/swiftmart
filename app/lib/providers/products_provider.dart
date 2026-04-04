import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../repositories/product_repository.dart';

final productsProvider = AsyncNotifierProvider<ProductsNotifier, List<Product>>(
  () {
    return ProductsNotifier();
  },
);

class ProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    final repo = ref.watch(productRepositoryProvider);
    return await repo.fetchProducts();
  }

  Future<void> fetchProducts({
    String? categoryId,
    String? search,
    bool? isOrganic,
    String? sort,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(productRepositoryProvider);
      final products = await repo.fetchProducts(
        categoryId: categoryId,
        search: search,
        isOrganic: isOrganic,
        sort: sort,
      );
      state = AsyncValue.data(products);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return await repo.fetchCategories();
});
