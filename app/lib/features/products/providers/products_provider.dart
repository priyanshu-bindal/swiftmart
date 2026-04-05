import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/category_model.dart';
import '../data/products_repository.dart';

final productsRepositoryProvider = Provider((ref) => ProductsRepository());

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repo = ref.watch(productsRepositoryProvider);
  return repo.getCategories();
});

final categoryProductsProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, categoryId) async {
      final repo = ref.watch(productsRepositoryProvider);
      return repo.getProductsByCategoryModel(categoryId);
    });

final searchProductsProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, query) async {
      final repo = ref.watch(productsRepositoryProvider);
      final res = await repo.getProducts(search: query, limit: 50);
      return res.products;
    });
