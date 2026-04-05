import 'dart:math' as math;
import 'package:flutter/material.dart';

class RiderMarkerIcon extends StatelessWidget {
  final double bearing;
  const RiderMarkerIcon({super.key, this.bearing = 0.0});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: bearing * (math.pi / 180),
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Color(0xFF6C3CE1),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.navigation,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
