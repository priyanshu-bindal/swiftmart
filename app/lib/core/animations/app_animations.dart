import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppAnimations {
  // Common durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);

  static Widget bounce(Widget child, {Duration? duration}) {
    return child.animate().scale(
      duration: duration ?? fast,
      curve: Curves.elasticOut,
      begin: const Offset(0.9, 0.9),
      end: const Offset(1.0, 1.0),
    );
  }

  static Widget fadeIn(Widget child, {Duration? duration, Duration? delay}) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: duration ?? medium, curve: Curves.easeIn);
  }

  static Widget slideUp(Widget child, {Duration? duration, Duration? delay}) {
    return child
        .animate(delay: delay)
        .slideY(
          begin: 0.2,
          end: 0.0,
          duration: duration ?? medium,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: duration ?? medium, curve: Curves.easeIn);
  }
}
