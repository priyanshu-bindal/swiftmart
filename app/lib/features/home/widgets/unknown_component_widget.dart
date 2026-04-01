import 'package:flutter/material.dart';

class UnknownComponentWidget extends StatelessWidget {
  final String componentType;

  const UnknownComponentWidget({super.key, required this.componentType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '⚠️ Unsupported Component',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Type: $componentType',
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
          const Text(
            'Please update the app to view this content.',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
