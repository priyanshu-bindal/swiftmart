import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrderPlacedScreen extends StatefulWidget {
  const OrderPlacedScreen({super.key});

  @override
  State<OrderPlacedScreen> createState() => _OrderPlacedScreenState();
}

class _OrderPlacedScreenState extends State<OrderPlacedScreen>
    with TickerProviderStateMixin {
  late AnimationController _modalController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  late AnimationController _checkController;
  late Animation<double> _checkAnimation;

  late AnimationController _stepsController;
  late Animation<double> _stepsAnimation;

  @override
  void initState() {
    super.initState();

    // Modal scale + fade entry (medium duration)
    _modalController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _modalController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _modalController, curve: Curves.easeIn),
    );

    // Animated checkmark draw-in (fast duration)
    _checkController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.easeOut),
    );

    // Progress steps left to right (slow duration)
    _stepsController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _stepsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _stepsController, curve: Curves.easeInOutCubic),
    );

    _playAnimations();
  }

  Future<void> _playAnimations() async {
    await _modalController.forward();
    await _checkController.forward();
    await _stepsController.forward();
  }

  @override
  void dispose() {
    _modalController.dispose();
    _checkController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Background Dark
      body: Center(
        child: disableAnimations
            ? _buildContent(disableAnimations)
            : ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildContent(disableAnimations),
                ),
              ),
      ),
    );
  }

  Widget _buildContent(bool disableAnimations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 10),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 100,
            width: 100,
            child: disableAnimations
                ? const Icon(Icons.check_circle, color: Color(0xFF2ECC71), size: 100)
                : AnimatedBuilder(
                    animation: _checkAnimation,
                    builder: (context, child) => CustomPaint(
                      painter: CheckmarkPainter(progress: _checkAnimation.value),
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Order Confirmed!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your groceries are on the way.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildSteps(disableAnimations),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C3CE1), // Primary Deep Violet
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              context.pushReplacement('/order-tracking');
            },
            child: const Text('Track Order',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          )
        ],
      ),
    );
  }

  Widget _buildSteps(bool disableAnimations) {
    if (disableAnimations) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
            4,
            (index) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    color: const Color(0xFF2ECC71),
                  ),
                )),
      );
    }
    return AnimatedBuilder(
      animation: _stepsAnimation,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) {
            double stepStart = index * 0.25;
            double stepEnd = stepStart + 0.25;
            double progress =
                ((_stepsAnimation.value - stepStart) / (stepEnd - stepStart))
                    .clamp(0.0, 1.0);
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                decoration: BoxDecoration(
                  color: Color.lerp(
                      const Color(0xFF4A4A6A), const Color(0xFF00D4AA), progress), // Teal Mint
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class CheckmarkPainter extends CustomPainter {
  final double progress;

  CheckmarkPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = const Color(0xFF2ECC71).withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2, bgPaint);

    final paint = Paint()
      ..color = const Color(0xFF2ECC71)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(size.width * 0.25, size.height * 0.5);
    path.lineTo(size.width * 0.45, size.height * 0.7);
    path.lineTo(size.width * 0.75, size.height * 0.3);

    if (progress > 0) {
      final pathMetrics = path.computeMetrics().first;
      final extractPath = pathMetrics.extractPath(0.0, pathMetrics.length * progress);
      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}