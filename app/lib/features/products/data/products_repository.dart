import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/models/category_model.dart';
import '../../../../core/models/banner_model.dart';
import '../../../../core/services/supabase_service.dart';

class ProductsRepository {
  Future<List<CategoryModel>> getCategories() async {
    final data = await Supabase.instance.client
        .from('categories')
        .select()
        .order('sort_order', ascending: true);
    return (data as List)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProductModel>> getProductsByCategoryModel(String categoryId) async {
    final data = await Supabase.instance.client
        .from('products')
        .select()
        .eq('category_id', categoryId)
        .eq('is_active', true)
        .order('name', ascending: true);
    return (data as List)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<({List<ProductModel> products, int count})> getProducts({
    String? categoryId,
    String? search,
    int page = 0,
    int limit = 20,
  }) async {
    var query = SupabaseService.client
        .from(SupabaseConstants.productsTable)
        .select('*, categories(name)')
        .eq('is_active', true);

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    }
    if (search != null && search.isNotEmpty) {
      query = query.ilike('name', '%$search%');
    }

    final response = await query
        .range(page * limit, (page + 1) * limit - 1)
        .order('created_at', ascending: false)
        .count(CountOption.exact);

    final count = response.count;
    final List<dynamic> data = response.data;

    final products = data.map((e) => ProductModel.fromJson(e)).toList();

    return (products: products, count: count);
  }

  Future<({ProductModel product, List<ProductModel> related})> getProductById(
    String id,
  ) async {
    final productData = await SupabaseService.client
        .from(SupabaseConstants.productsTable)
        .select('*, categories(name)')
        .eq('id', id)
        .single();

    final product = ProductModel.fromJson(productData);

    List<ProductModel> related = [];
    if (product.categoryId != null) {
      final relatedData = await SupabaseService.client
          .from(SupabaseConstants.productsTable)
          .select('*, categories(name)')
          .eq('is_active', true)
          .eq('category_id', product.categoryId!)
          .neq('id', id)
          .limit(6);

      related = relatedData.map((e) => ProductModel.fromJson(e)).toList();
    }

    return (product: product, related: related);
  }

  Future<List<Map<String, dynamic>>> getFlashDeals() async {
    final now = DateTime.now().toUtc().toIso8601String();

    final data = await SupabaseService.client
        .from(SupabaseConstants.flashDealsTable)
        .select('*, products(*)')
        .eq('is_active', true)
        .lte('start_time', now)
        .gte('end_time', now);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<BannerModel>> getBanners() async {
    final data = await SupabaseService.client
        .from(SupabaseConstants.bannersTable)
        .select()
        .eq('is_active', true)
        .order('display_order', ascending: true);

    return data.map((e) => BannerModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getHomeConfigModel() async {
    final data = await SupabaseService.client
        .from(SupabaseConstants.homeConfigTable)
        .select()
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();

    return data ?? {};
  }
}
