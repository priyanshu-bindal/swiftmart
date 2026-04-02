import 'package:dio/dio.dart';
import '../models/order_model.dart';

class DioOrderRepository {
  final Dio _dio;

  DioOrderRepository(this._dio);

  // 1. POST /api/v1/orders — Create order
  Future<OrderModel> createOrder(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/v1/orders', data: data);
    return OrderModel.fromJson(response.data['order']);
  }

  // 2. GET /api/v1/orders/:orderId — Fetch single order
  Future<OrderModel> getOrderById(String orderId) async {
    final response = await _dio.get('/api/v1/orders/$orderId');
    return OrderModel.fromJson(response.data['order']);
  }

  // 3. GET /api/v1/orders/user/:userId — Fetch order history
  Future<List<OrderModel>> getUserOrders(String userId) async {
    final response = await _dio.get('/api/v1/orders/user/$userId');
    final List list = response.data['orders'] ?? [];
    return list.map((e) => OrderModel.fromJson(e)).toList();
  }

  // 4. PATCH /api/v1/orders/:orderId/status — Update order status
  Future<OrderModel> updateOrderStatus(String orderId, String status, {Map<String, dynamic>? riderLocation}) async {
    final response = await _dio.patch(
      '/api/v1/orders/$orderId/status',
      data: {
        'status': status,
        if (riderLocation != null) 'riderLocation': riderLocation,
      },
    );
    return OrderModel.fromJson(response.data['order']);
  }
}