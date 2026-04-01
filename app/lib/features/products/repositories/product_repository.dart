import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/product.dart';

final productRepositoryProvider = Provider((ref) => ProductRepository());

class ProductRepository {
  // Master mock product list
  List<Product> get _allProducts => [
    const Product(
      id: 'p1',
      name: 'Milk 1L',
      imagePath: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&q=80',
      price: 2.50,
      unit: '1L Pack',
      isOrganic: true,
      rating: 4.8,
      reviewCount: 1240,
    ),
    const Product(
      id: 'p2',
      name: 'Bread Brown',
      imagePath: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&q=80',
      price: 3.20,
      unit: '1 Loaf',
      rating: 4.5,
      reviewCount: 320,
    ),
    const Product(
      id: 'p3',
      name: 'Fresh Mangoes',
      imagePath: 'https://images.unsplash.com/photo-1553279768-865429fa0078?auto=format&fit=crop&q=80',
      price: 12.50,
      originalPrice: 15.00,
      unit: '500g',
      isOrganic: true,
      rating: 4.9,
      reviewCount: 340,
    ),
    const Product(
      id: 'p4',
      name: 'Cold Drink Coca Cola',
      imagePath: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&q=80',
      price: 1.99,
      unit: '500ml Bottle',
      rating: 4.2,
      reviewCount: 89,
    ),
    const Product(
      id: 'p5',
      name: 'Vanilla Ice Cream',
      imagePath: 'https://images.unsplash.com/photo-1570197781417-0c7f8c0576a0?auto=format&fit=crop&q=80',
      price: 8.20,
      unit: '1L Tub',
      rating: 4.8,
      reviewCount: 512,
    ),
    const Product(
      id: 'p6',
      name: 'Greek Yogurt',
      imagePath: 'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&q=80',
      price: 4.50,
      unit: '400g Cup',
      rating: 4.7,
      reviewCount: 220,
    ),
    const Product(
      id: 'p7',
      name: 'Organic Eggs',
      imagePath: 'https://images.unsplash.com/photo-1598965402089-897ce52e8355?auto=format&fit=crop&q=80',
      price: 5.99,
      unit: 'Dozen',
      isOrganic: true,
      rating: 4.9,
      reviewCount: 610,
    ),
    const Product(
      id: 'p8',
      name: 'Potato Chips',
      imagePath: 'https://images.unsplash.com/photo-1563013734-52300f97cd60?auto=format&fit=crop&q=80',
      price: 2.99,
      unit: '150g Bag',
      rating: 4.4,
      reviewCount: 156,
    ),
  ];

  Future<List<Product>> searchProducts(String query) async {
    // Instant search, no delay
    if (query.trim().isEmpty) return [];

    final q = query.trim().toLowerCase();
    return _allProducts.where((p) {
      final matchesName = p.name.toLowerCase().contains(q);
      final matchesBrand = (p.brand?.toLowerCase() ?? '').contains(q);
      return matchesName || matchesBrand;
    }).toList();
  }

  Product? getProductById(String id) {
    try {
      return _allProducts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
