import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/supabase_provider.dart';
import 'package:app/core/models/product_model.dart';
import 'package:app/core/models/category_model.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ProductRepository(supabase: supabase);
});

class ProductRepository {
  final SupabaseClient supabase;

  ProductRepository({required this.supabase});

  Future<List<ProductModel>> fetchProducts({
    String? categoryId,
    String? search,
    bool? organicOnly,
    String? sort, // 'price_asc' | 'price_desc'
  }) async {
    var baseQuery = supabase
        .from('products')
        .select('*, categories(name)')
        .eq('is_active', true);

    if (categoryId != null) {
      baseQuery = baseQuery.eq('category_id', categoryId);
    }
    if (search != null && search.isNotEmpty) {
      baseQuery = baseQuery.ilike('name', '%$search%');
    }
    if (organicOnly == true) {
      baseQuery = baseQuery.contains('tags', ['organic']);
    }

    PostgrestTransformBuilder<PostgrestList> finalQuery;
    if (sort == 'price_asc') {
      finalQuery = baseQuery.order('sale_price', ascending: true);
    } else if (sort == 'price_desc') {
      finalQuery = baseQuery.order('sale_price', ascending: false);
    } else {
      finalQuery = baseQuery.order('id', ascending: false);
    }

    final response = await finalQuery;
    return (response as List<dynamic>)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductModel?> fetchProductById(String id) async {
    final response = await supabase
        .from('products')
        .select('*, categories(name)')
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return ProductModel.fromJson(response);
  }

  Future<List<CategoryModel>> fetchCategories() async {
    final response = await supabase
        .from('categories')
        .select()
        .order('sort_order', ascending: true);
    return (response as List<dynamic>)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
