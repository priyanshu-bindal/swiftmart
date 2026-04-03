import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  final String userId;
  const OrderHistoryScreen({super.key, required this.userId});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(orderHistoryProvider);
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Background dark
      appBar: AppBar(
        title: const Text('Order History', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6C3CE1), // Primary Deep Violet
        elevation: 0,
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
                child: Text('No orders found.',
                    style: TextStyle(color: Colors.white70)));
          }

          if (!disableAnimations) {
            _listController.forward();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];

              if (disableAnimations) {
                return _buildOrderItem(order, disableAnimations);
              }

              final Animation<double> animation = Tween<double>(begin: 0.0, end: 1.0)
                  .animate(CurvedAnimation(
                parent: _listController,
                curve: Interval(
                    (index / orders.length).clamp(0.0, 1.0), 1.0,
                    curve: Curves.easeOut),
              ));

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0, 0.2), end: Offset.zero)
                      .animate(animation),
                  child: _buildOrderItem(order, disableAnimations),
                ),
              );
            },
          );
        },
        loading: () => _buildShimmer(disableAnimations),
        error: (e, st) => Center(
            child: Text('Error loading orders: $e',
                style: const TextStyle(color: Color(0xFFFF6B6B)))),
      ),
    );
  }

  Widget _buildOrderItem(OrderModel order, bool disableAnimations) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order #${order.id.substring(0, 8)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              AnimatedStatusChip(
                  status: order.status, disableAnimations: disableAnimations),
            ],
          ),
          const SizedBox(height: 16),
          Text('\$${order.totalAmount.toStringAsFixed(2)} • ${order.paymentMethod}',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          TimelineDots(status: order.status, disableAnimations: disableAnimations),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _formatDate(order.createdAt),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          )
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildShimmer(bool disableAnimations) {
    // Shimmer skeleton
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A3E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: disableAnimations
              ? const SizedBox.shrink()
              : TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.3, end: 0.6),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: value),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class AnimatedStatusChip extends StatelessWidget {
  final String status;
  final bool disableAnimations;
  const AnimatedStatusChip(
      {super.key, required this.status, required this.disableAnimations});

  Color _getStatusColor() {
    switch (status) {
      case 'DELIVERED':
        return const Color(0xFF2ECC71); // Success
      case 'PENDING':
      case 'PREPARING':
      case 'OUT_FOR_DELIVERY':
      case 'CONFIRMED':
        return const Color(0xFFF39C12); // Warning
      case 'CANCELLED':
      case 'FAILED':
        return const Color(0xFFFF6B6B); // Accent Coral Red
      default:
        return const Color(0xFF00D4AA); // Secondary Teal Mint
    }
  }

  @override
  Widget build(BuildContext context) {
    if (disableAnimations) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getStatusColor().withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(status,
            style: TextStyle(
                color: _getStatusColor(), fontWeight: FontWeight.bold)),
      );
    }
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: const Color(0xFF00D4AA), end: _getStatusColor()),
      duration: const Duration(milliseconds: 400), // Medium
      builder: (context, color, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (color ?? _getStatusColor()).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(status,
              style: TextStyle(
                  color: color ?? _getStatusColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        );
      },
    );
  }
}

class TimelineDots extends StatefulWidget {
  final String status;
  final bool disableAnimations;
  const TimelineDots(
      {super.key, required this.status, required this.disableAnimations});

  @override
  State<TimelineDots> createState() => _TimelineDotsState();
}

class _TimelineDotsState extends State<TimelineDots>
    with TickerProviderStateMixin {
  late AnimationController _dotsController;

  final List<String> _stages = [
    'PENDING',
    'CONFIRMED',
    'PREPARING',
    'OUT_FOR_DELIVERY',
    'DELIVERED'
  ];

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800)); // Slow
    if (!widget.disableAnimations) {
      _dotsController.forward();
    }
  }

  @override
  void didUpdateWidget(TimelineDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status && !widget.disableAnimations) {
      _dotsController.reset();
      _dotsController.forward();
    }
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int currentStageIndex = _stages.indexOf(widget.status);
    if (currentStageIndex == -1) currentStageIndex = 0; // fallback if cancelled

    return Row(
      children: List.generate(_stages.length, (index) {
        bool isActive = index <= currentStageIndex;

        Widget dot = Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFF00D4AA) : const Color(0xFF4A4A6A),
          ),
        );

        if (widget.disableAnimations) {
          return Expanded(
            child: Row(
              children: [
                dot,
                if (index < _stages.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isActive
                          ? const Color(0xFF00D4AA)
                          : const Color(0xFF4A4A6A),
                    ),
                  )
              ],
            ),
          );
        }

        final Animation<double> animation = Tween<double>(begin: 0.0, end: 1.0)
            .animate(CurvedAnimation(
          parent: _dotsController,
          curve: Interval((index / _stages.length).clamp(0.0, 1.0), 1.0,
              curve: Curves.easeOut),
        ));

        return Expanded(
          child: Row(
            children: [
              ScaleTransition(scale: animation, child: dot),
              if (index < _stages.length - 1)
                Expanded(
                  child: FadeTransition(
                    opacity: animation,
                    child: Container(
                      height: 2,
                      color: isActive
                          ? const Color(0xFF00D4AA)
                          : const Color(0xFF4A4A6A),
                    ),
                  ),
                )
            ],
          ),
        );
      }),
    );
  }
}