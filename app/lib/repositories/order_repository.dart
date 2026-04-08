import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/supabase_provider.dart';
import 'package:app/core/models/order_model.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return OrderRepository(supabase: supabase);
});

class OrderRepository {
  final SupabaseClient supabase;

  OrderRepository({required this.supabase});

  String _getUid() {
    final id = supabase.auth.currentUser?.id;
    if (id == null) throw Exception('User not authenticated');
    return id;
  }

  Future<OrderModel> placeOrderModel({
    required String deliveryAddress,
    double? lat,
    double? lng,
    String paymentMethod = 'cod',
  }) async {
    final uid = _getUid();

    // 1. Fetch cart items
    final cartRes = await supabase
        .from('cart_items')
        .select('*, products(*)')
        .eq('user_id', uid);

    final cartList = cartRes as List<dynamic>;
    if (cartList.isEmpty) throw Exception("Cart is empty");

    // 2. Calculate local total
    double totalAmount = 0.0;
    for (var item in cartList) {
      final price = (item['products']['price'] as num).toDouble();
      final quantity = item['quantity'] as int;
      totalAmount += price * quantity;
    }

    // 3. Insert OrderModel
    final orderRes = await supabase
        .from('orders')
        .insert({
          'user_id': uid,
          'status': 'placed',
          'total_amount': totalAmount,
          'delivery_address': deliveryAddress,
          'delivery_lat': lat,
          'delivery_lng': lng,
          'payment_method': paymentMethod,
          'estimated_minutes': 28, // mock estimate
        })
        .select()
        .single();

    final insertedOrderId = orderRes['id'];

    // 4. Insert OrderModel items
    final List<Map<String, dynamic>> orderItemsToInsert = cartList.map((item) {
      return {
        'order_id': insertedOrderId,
        'product_id': item['product_id'],
        'product_name': item['products']['name'],
        'product_image': item['products']['image_url'],
        'unit_size': item['products']['unit_size'],
        'quantity': item['quantity'],
        'price_at_order': item['products']['price'],
      };
    }).toList();

    await supabase.from('order_items').insert(orderItemsToInsert);

    // 5. Clear cart
    await supabase.from('cart_items').delete().eq('user_id', uid);

    // 6. Return created OrderModel
    return fetchOrderById(insertedOrderId as String);
  }

  Future<List<OrderModel>> fetchOrders() async {
    final uid = _getUid();
    final response = await supabase
        .from('orders')
        .select('*, order_items(*)')
        .eq('user_id', uid)
        .order('placed_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrderModel> fetchOrderById(String id) async {
    final uid = _getUid();
    final response = await supabase
        .from('orders')
        .select('*, order_items(*)')
        .eq('id', id)
        .eq('user_id', uid)
        .single();

    return OrderModel.fromJson(response);
  }
}
