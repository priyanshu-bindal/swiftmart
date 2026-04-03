import 'package:socket_io_client/socket_io_client.dart' as io_client;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/order_provider.dart';
import '../models/order_model.dart';

class SocketService {
  late io_client.Socket socket;
  final Ref ref;

  SocketService(this.ref);

  void connect(String serverUrl, String orderId) {
    socket = io_client.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    // Join room for specific order
    socket.emit('joinRoom', 'order_$orderId');

    socket.on('order:status_updated', (data) {
      if (data != null && data['status'] != null) {
        final activeOrder = ref.read(activeOrderProvider);
        if (activeOrder != null && activeOrder.id == data['orderId']) {
          final updatedOrder = OrderModel(
            id: activeOrder.id,
            userId: activeOrder.userId,
            totalAmount: activeOrder.totalAmount,
            deliveryFee: activeOrder.deliveryFee,
            discountAmount: activeOrder.discountAmount,
            status: data['status'],
            paymentMethod: activeOrder.paymentMethod,
            createdAt: activeOrder.createdAt,
            items: activeOrder.items,
          );
          ref.read(activeOrderProvider.notifier).setOrder(updatedOrder);
        }
      }
    });
  }

  void disconnect() {
    socket.disconnect();
  }
}

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService(ref);
});
