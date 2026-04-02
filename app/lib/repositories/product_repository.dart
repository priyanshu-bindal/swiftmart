import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/supabase_provider.dart';
import '../models/product.dart';
import '../models/category.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ProductRepository(supabase: supabase);
});

class ProductRepository {
  final SupabaseClient supabase;

  ProductRepository({required this.supabase});

  Future<List<Product>> fetchProducts({
    String? categoryId,
    String? search,
    bool? isOrganic,
    String? sort, // 'price_asc' | 'price_desc'
  }) async {
    var baseQuery = supabase
        .from('products')
        .select('*, categories(name)')
        .eq('is_available', true);

    if (categoryId != null) {
      baseQuery = baseQuery.eq('category_id', categoryId);
    }
    if (search != null && search.isNotEmpty) {
      baseQuery = baseQuery.ilike('name', '%$search%');
    }
    if (isOrganic != null) {
      baseQuery = baseQuery.eq('is_organic', isOrganic);
    }
    
    PostgrestTransformBuilder<PostgrestList> finalQuery;
    if (sort == 'price_asc') {
      finalQuery = baseQuery.order('price', ascending: true);
    } else if (sort == 'price_desc') {
      finalQuery = baseQuery.order('price', ascending: false);
    } else {
      finalQuery = baseQuery.order('created_at', ascending: false);
    }

    final response = await finalQuery;
    return (response as List<dynamic>).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Product?> fetchProductById(String id) async {
    try {
      final response = await supabase.from('products').select().eq('id', id).single();
      return Product.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  Future<List<Category>> fetchCategories() async {
    final response = await supabase.from('categories').select().order('sort_order', ascending: true);
    return (response as List<dynamic>).map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }
}
