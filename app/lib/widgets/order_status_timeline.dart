import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OrderStatusTimeline extends StatelessWidget {
  final int currentStepIndex;

  const OrderStatusTimeline({
    super.key,
    this.currentStepIndex = 3, // Default active: On the Way (0-based: 0,1,2,3)
  });

  final List<String> _steps = const [
    'Order Placed',
    'Being Packed',
    'Picked Up',
    'On the Way',
  ];

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_steps.length, (index) {
        final isCompleted = index < currentStepIndex;
        final isActive = index == currentStepIndex;

        Widget row = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                _buildDot(isCompleted, isActive, disableAnimations),
                if (index < _steps.length - 1)
                  Container(
                    width: 2,
                    height: 24,
                    color: isCompleted
                        ? const Color(0xFF00D4AA)
                        : const Color(0xFF4A4A6A),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _steps[index],
                  style: TextStyle(
                    color: (isCompleted || isActive)
                        ? Colors.white
                        : Colors.white54,
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        );

        if (disableAnimations) {
          return row;
        }

        // Animate incoming from the left with stagger
        return row
            .animate(delay: (400 + index * 150).ms)
            .fadeIn(duration: 400.ms, curve: Curves.easeOut)
            .slideX(begin: -0.1, end: 0, curve: Curves.easeOut);
      }),
    );
  }

  Widget _buildDot(bool isCompleted, bool isActive, bool disableAnimations) {
    if (isCompleted) {
      return Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: Color(0xFF00D4AA), // Teal Mint
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 14, color: Color(0xFF1A1A2E)),
      );
    } else if (isActive) {
      return RepaintBoundary(
        child: AnimatedActiveDot(disableAnimations: disableAnimations),
      );
    } else {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF4A4A6A), width: 2),
        ),
      );
    }
  }
}

class AnimatedActiveDot extends StatefulWidget {
  final bool disableAnimations;
  const AnimatedActiveDot({super.key, required this.disableAnimations});

  @override
  State<AnimatedActiveDot> createState() => _AnimatedActiveDotState();
}

class _AnimatedActiveDotState extends State<AnimatedActiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (!widget.disableAnimations) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.disableAnimations) {
      return Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: Color(0xFFF39C12), // Orange bouncing dot
          shape: BoxShape.circle,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFF39C12), // Orange bouncing dot
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF39C12).withValues(alpha: 0.5),
                  blurRadius: 8 * _scaleAnimation.value,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
