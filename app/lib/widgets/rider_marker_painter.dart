import 'dart:math' as math;
import 'package:flutter/material.dart';

class RiderMarkerIcon extends StatefulWidget {
  final double bearing; // Calculated rotation

  const RiderMarkerIcon({
    super.key,
    this.bearing = 0.0,
  });

  @override
  State<RiderMarkerIcon> createState() => _RiderMarkerIconState();
}

class _RiderMarkerIconState extends State<RiderMarkerIcon>
    with TickerProviderStateMixin {
  // Glow ring
  late AnimationController _glowController;
  late Animation<double> _glowRadiusAnimation;
  late Animation<double> _glowOpacityAnimation;

  // Wheels and speed
  late AnimationController _continuousController;

  @override
  void initState() {
    super.initState();

    // Pulse a #00D4AA ring every 1.5 seconds
    _glowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _glowRadiusAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeOutCubic),
    );
    _glowOpacityAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.6), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 0.6, end: 0.0), weight: 80),
    ]).animate(_glowController);

    // Continuous rotation for wheels & pulsing motion blur/speed lines
    _continuousController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    final disableAnimations =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;

    if (!disableAnimations) {
      _glowController.repeat();
      _continuousController.repeat();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _continuousController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: widget.bearing * math.pi / 180,
      child: AnimatedBuilder(
        animation: Listenable.merge([_glowController, _continuousController]),
        builder: (context, child) {
          final disableAnimations = MediaQuery.of(context).disableAnimations;

          return CustomPaint(
            size: const Size(60, 60),
            painter: RiderMarkerPainter(
              disableAnimations: disableAnimations,
              glowRadius: disableAnimations ? 1.0 : _glowRadiusAnimation.value,
              glowOpacity: disableAnimations ? 0.0 : _glowOpacityAnimation.value,
              continuousTime: _continuousController.value,
            ),
          );
        },
      ),
    );
  }
}

class RiderMarkerPainter extends CustomPainter {
  final bool disableAnimations;
  final double glowRadius;
  final double glowOpacity;
  final double continuousTime;

  RiderMarkerPainter({
    required this.disableAnimations,
    required this.glowRadius,
    required this.glowOpacity,
    required this.continuousTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final riderWidth = 24.0;
    final riderHeight = 32.0;

    // Glowing Ring
    if (glowOpacity > 0) {
      final ringPaint = Paint()
        ..color = const Color(0xFF00D4AA).withValues(alpha: glowOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, (riderHeight / 2) * glowRadius + 10, ringPaint);
    }

    // Motion blur trailing oval (behind the rider based on orientation — let's put it "below" assuming forward is top)
    if (!disableAnimations) {
      final blurPulse = (math.sin(continuousTime * math.pi * 2) + 1) / 2; // 0 to 1
      final blurPaint = Paint()
        ..color = const Color(0xFF6C3CE1).withValues(alpha: 0.2 + blurPulse * 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      final blurRect = RRect.fromLTRBR(
        center.dx - riderWidth / 2,
        center.dy, 
        center.dx + riderWidth / 2,
        center.dy + riderHeight,
        const Radius.circular(8)
      );
      canvas.drawRRect(blurRect, blurPaint);

      // Speed lines on left
      final linesPaint = Paint()
        ..color = Colors.white.withValues(alpha: blurPulse * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      // Draw 3 lines
      for (int i = 0; i < 3; i++) {
        double yy = center.dy - 10 + i * 10;
        double lineLen = 6.0 + (i % 2) * 4;
        canvas.drawLine(
            Offset(center.dx - riderWidth / 2 - 8, yy),
            Offset(center.dx - riderWidth / 2 - 8 - lineLen, yy + lineLen * 0.5),
            linesPaint);
      }
    }

    // Body Gradient
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF8E54E9), Color(0xFF6C3CE1)], // Brighter to Deep Violet
      ).createShader(Rect.fromCenter(center: center, width: riderWidth, height: riderHeight));

    final bodyRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: riderWidth, height: riderHeight),
        const Radius.circular(6));
    canvas.drawRRect(bodyRect, bodyPaint);

    // Box details (Top flap of delivery bag)
    final detailPaint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(center.dx - riderWidth/2 + 2, center.dy - riderHeight/2 + 4, riderWidth - 4, 6),
      detailPaint
    );

    // Wheels (two rotating circles on the sides)
    final wheelPaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.fill;
      
    final axlePaint = Paint()
      ..color = Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final wheelRadius = 5.0;
    final List<Offset> wheelCenters = [
      Offset(center.dx - riderWidth / 2 - wheelRadius + 2, center.dy + riderHeight / 4), // Left rear
      Offset(center.dx + riderWidth / 2 + wheelRadius - 2, center.dy + riderHeight / 4), // Right rear
    ];

    double wheelRot = disableAnimations ? 0 : continuousTime * math.pi * 2;

    for (final wc in wheelCenters) {
      canvas.drawCircle(wc, wheelRadius, wheelPaint);
      
      // Draw spokes/axle for rotation effect
      canvas.save();
      canvas.translate(wc.dx, wc.dy);
      canvas.rotate(wheelRot);
      canvas.drawLine(Offset(-wheelRadius, 0), Offset(wheelRadius, 0), axlePaint);
      canvas.drawLine(Offset(0, -wheelRadius), Offset(0, wheelRadius), axlePaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant RiderMarkerPainter oldDelegate) {
    return oldDelegate.disableAnimations != disableAnimations ||
        oldDelegate.glowRadius != glowRadius ||
        oldDelegate.glowOpacity != glowOpacity ||
        oldDelegate.continuousTime != continuousTime;
  }
}
