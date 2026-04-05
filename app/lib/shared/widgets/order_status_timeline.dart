import 'package:flutter/material.dart';

class OrderStatusTimeline extends StatelessWidget {
  final int currentStepIndex;
  const OrderStatusTimeline({super.key, required this.currentStepIndex});

  static const _stages = [
    ('Order Placed', Icons.receipt_outlined),
    ('Confirmed', Icons.check_circle_outline),
    ('Preparing', Icons.restaurant_outlined),
    ('Out for Delivery', Icons.delivery_dining_outlined),
    ('Delivered', Icons.home_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_stages.length, (i) {
        final isActive = i <= currentStepIndex;
        final (label, icon) = _stages[i];
        return Row(
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF00D4AA) : Colors.white24,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white38,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (i < _stages.length - 1) ...[
              const SizedBox(width: 8),
            ],
          ],
        );
      }),
    );
  }
}
