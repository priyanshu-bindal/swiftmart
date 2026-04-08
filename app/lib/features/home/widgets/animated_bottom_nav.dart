import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

// --- DATA MODEL ---
class NavItem {
  final String id;
  final String label;
  final int badgeCount;

  const NavItem({
    required this.id,
    required this.label,
    this.badgeCount = 0,
  });
}

// --- THE NAVBAR WIDGET ---
class SwiftmartBottomNav extends StatelessWidget {
  final String currentTab;
  final ValueChanged<String> onTabSelected;
  final int cartBadgeCount;

  const SwiftmartBottomNav({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
    this.cartBadgeCount = 0,
  });

  // Navigation Items matching the Custom Canvas Icons
  List<NavItem> get items => [
    const NavItem(
      id: 'home',
      label: 'Home',
    ),
    const NavItem(
      id: 'category',
      label: 'Category',
    ),
    NavItem(
      id: 'cart',
      label: 'Cart',
      badgeCount: cartBadgeCount,
    ),
    const NavItem(
      id: 'orders',
      label: 'Orders',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      // The floating margin
      margin: EdgeInsets.only(
        left: 24,
        right: 24,
        // Lift above gesture bar
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      // Shadow applied outside the clip so it doesn't get cut off
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.blueGrey[100]!.withValues(alpha: 0.7),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: items.map((item) {
                final isActive = item.id == currentTab;
                return _ExpandingPillTab(
                  item: item,
                  isActive: isActive,
                  onTap: () => onTabSelected(item.id),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// --- INDIVIDUAL ANIMATED TAB ---
class _ExpandingPillTab extends StatefulWidget {
  final NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _ExpandingPillTab({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_ExpandingPillTab> createState() => _ExpandingPillTabState();
}

class _ExpandingPillTabState extends State<_ExpandingPillTab> {
  // Track press state for tactile scale effect
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // New Dark Blue Theme
    final activeColor = Colors.blue[900]!; 
    const inactiveColor = Color(0xFF78909C); // blueGrey[400] roughly
    final activeBgColor = Colors.blue[50]!; 

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Handle touch states to trigger the shrink animation
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0, // Replicates React's "active:scale-95"
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isActive ? 16.0 : 12.0,
            vertical: 12.0,
          ),
          decoration: BoxDecoration(
            color: widget.isActive ? activeBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon & Notification Badge Stack
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 300),
                    scale: widget.isActive ? 26 / 24 : 1.0, // Scale 24 to 26
                    child: _AnimatedCustomIcon(
                      id: widget.item.id,
                      isActive: widget.isActive,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      activeBgColor: activeBgColor,
                    ),
                  ),

                  // Hide badge when active or when count is 0
                  if (widget.item.badgeCount > 0 && !widget.isActive)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          widget.item.badgeCount > 99
                              ? '99+'
                              : '${widget.item.badgeCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Animated Expanding Label
              AnimatedSize(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  // Width drops to 0 when inactive to completely hide
                  width: widget.isActive ? null : 0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: Text(
                      widget.item.label,
                      maxLines: 1,
                      style: TextStyle(
                        color: activeColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- CORE CUSTOM ICON ANIMATION CONTROLLER ---
class _AnimatedCustomIcon extends StatefulWidget {
  final String id;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final Color activeBgColor;

  const _AnimatedCustomIcon({
    required this.id,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.activeBgColor,
  });

  @override
  __AnimatedCustomIconState createState() => __AnimatedCustomIconState();
}

class __AnimatedCustomIconState extends State<_AnimatedCustomIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    if (widget.isActive) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(_AnimatedCustomIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        CustomPainter painter;
        // Route to the specific Canvas drawing based on ID
        switch (widget.id) {
          case 'home':
            painter = _HomePainter(_controller.value, widget.activeColor,
                widget.inactiveColor, widget.activeBgColor);
            break;
          case 'category':
            painter = _CategoryPainter(_controller.value, widget.activeColor,
                widget.inactiveColor, widget.activeBgColor);
            break;
          case 'cart':
            painter = _CartPainter(_controller.value, widget.activeColor,
                widget.inactiveColor, widget.activeBgColor);
            break;
          case 'orders':
          default:
            painter = _HistoryPainter(_controller.value, widget.activeColor,
                widget.inactiveColor, widget.activeBgColor);
            break;
        }

        return CustomPaint(
          size: const Size(24, 24),
          painter: painter,
        );
      },
    );
  }
}

// ============================================================================
// CUSTOM PAINTERS (The exact SVG Paths translated to Flutter Canvas)
// ============================================================================

// 1. Home Icon Painter
class _HomePainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final Color activeBgColor;

  _HomePainter(
      this.progress, this.activeColor, this.inactiveColor, this.activeBgColor);

  @override
  void paint(Canvas canvas, Size size) {
    final color = Color.lerp(inactiveColor, activeColor, progress)!;

    final paintStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final paintFill = Paint()
      ..color = color.withValues(alpha: progress)
      ..style = PaintingStyle.fill;

    // Door punch-out effect
    final doorColor = Color.lerp(Colors.transparent, activeBgColor, progress)!;
    final paintDoorStroke = Paint()
      ..color = Color.lerp(color, activeBgColor, progress)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final paintDoorFill = Paint()
      ..color = doorColor
      ..style = PaintingStyle.fill;

    // Paths
    Path base = Path()
      ..moveTo(5, 10)
      ..lineTo(5, 20)
      ..arcToPoint(const Offset(7, 22),
          radius: const Radius.circular(2), clockwise: false)
      ..lineTo(17, 22)
      ..arcToPoint(const Offset(19, 20),
          radius: const Radius.circular(2), clockwise: false)
      ..lineTo(19, 10);

    Path door = Path()
      ..moveTo(9, 22)
      ..lineTo(9, 12)
      ..lineTo(15, 12)
      ..lineTo(15, 22)
      ..close();

    Path roof = Path()
      ..moveTo(3, 10)
      ..lineTo(12, 3)
      ..lineTo(21, 10);

    // Draw Base
    if (progress > 0) canvas.drawPath(base, paintFill);
    canvas.drawPath(base, paintStroke);

    // Draw Door (Punch-out)
    if (progress > 0) canvas.drawPath(door, paintDoorFill);
    canvas.drawPath(door, paintDoorStroke);

    // Draw Roof (Animated Bounce)
    // Sin wave provides a gentle bounce up and down
    final roofY = -3.0 * math.sin(progress * math.pi);
    final roofScale = 1.0 + 0.05 * math.sin(progress * math.pi);

    canvas.save();
    canvas.translate(12, 12); // Move origin to center
    canvas.scale(roofScale);
    canvas.translate(-12, -12 + roofY);
    paintStroke.strokeWidth = 2.0 + (0.5 * progress); // Thicken on active

    if (progress > 0) canvas.drawPath(roof, paintFill);
    canvas.drawPath(roof, paintStroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HomePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// 2. Category Icon Painter
class _CategoryPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final Color activeBgColor;

  _CategoryPainter(
      this.progress, this.activeColor, this.inactiveColor, this.activeBgColor);

  @override
  void paint(Canvas canvas, Size size) {
    final color = Color.lerp(inactiveColor, activeColor, progress)!;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color.withValues(alpha: progress)
      ..style = PaintingStyle.fill;

    // Helper to draw a single staggered animated square
    void drawSq(double x, double y, double delayOffset) {
      // Stagger the animation timing based on delayOffset
      double t = (progress * 1.5 - delayOffset).clamp(0.0, 1.0);

      canvas.save();
      final cx = x + 3.5;
      final cy = y + 3.5;
      canvas.translate(cx, cy);
      // Rotate 15 degrees during the animation curve
      canvas.rotate((15 * math.pi / 180) * math.sin(t * math.pi));
      // Scale down slightly during the animation curve
      canvas.scale(1.0 - 0.2 * math.sin(t * math.pi));
      canvas.translate(-cx, -cy);

      final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, 7, 7), Radius.circular(1.0 + t));

      if (t > 0) canvas.drawRRect(rrect, fill);
      canvas.drawRRect(rrect, stroke);
      canvas.restore();
    }

    drawSq(3, 3, 0.0); // Top Left
    drawSq(14, 3, 0.15); // Top Right
    drawSq(14, 14, 0.30); // Bottom Right
    drawSq(3, 14, 0.45); // Bottom Left
  }

  @override
  bool shouldRepaint(covariant _CategoryPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// 3. Cart Icon Painter
class _CartPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final Color activeBgColor;

  _CartPainter(
      this.progress, this.activeColor, this.inactiveColor, this.activeBgColor);

  @override
  void paint(Canvas canvas, Size size) {
    final color = Color.lerp(inactiveColor, activeColor, progress)!;

    final paintStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final paintFill = Paint()
      ..color = color.withValues(alpha: progress)
      ..style = PaintingStyle.fill;

    Path handle = Path()
      ..moveTo(1, 1)
      ..lineTo(5, 1)
      ..lineTo(6, 6);

    Path basket = Path()
      ..moveTo(6, 6)
      ..lineTo(7.68, 14.39)
      ..arcToPoint(const Offset(9.68, 16),
          radius: const Radius.circular(2), clockwise: false)
      ..lineTo(19.4, 16)
      ..arcToPoint(const Offset(21.4, 14.39),
          radius: const Radius.circular(2), clockwise: false)
      ..lineTo(23, 6)
      ..lineTo(6, 6)
      ..close();

    // Drive and Bump Animation Logic (Mimicking CSS Keyframes)
    // Sine wave pushes X out to 4px and back, and applies a slight rotation
    final bumpCurve = math.sin(progress * math.pi);
    final driveCurve = math.sin(progress * math.pi * 2);
    
    double translateX = driveCurve * 4.0;
    double rotateBump = driveCurve * 6.0 * (math.pi / 180.0);

    canvas.save();
    canvas.translate(12, 21); // Anchor at bottom center for cart rotation
    canvas.translate(translateX, 0);
    canvas.rotate(rotateBump);
    // Slight scale bump
    canvas.scale(1.0 + (0.05 * bumpCurve)); 
    canvas.translate(-12, -21);

    // Draw Cart Handle
    canvas.drawPath(handle, paintStroke);

    // Draw Cart Basket
    if (progress > 0) canvas.drawPath(basket, paintFill);
    canvas.drawPath(basket, paintStroke);

    // Draw Wheels (with rolling animation)
    final wheelRotation = progress * 2.0 * math.pi;

    void drawWheel(double cx, double cy) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(wheelRotation);
      
      // Draw actual wheel
      if (progress > 0) {
        canvas.drawCircle(Offset.zero, 1.5, paintFill);
      }
      canvas.drawCircle(Offset.zero, 1.5, paintStroke);
      
      // Add a tiny dot inside the wheel to make the rotation visible!
      if (progress == 0) {
          final wheelSpoke = Paint()..color = color..style = PaintingStyle.fill;
          canvas.drawCircle(const Offset(0.8, 0.8), 0.5, wheelSpoke);
      }
      
      canvas.restore();
    }

    drawWheel(9, 21);
    drawWheel(20, 21);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CartPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// 4. History / Orders Icon Painter
class _HistoryPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final Color activeBgColor;

  _HistoryPainter(
      this.progress, this.activeColor, this.inactiveColor, this.activeBgColor);

  @override
  void paint(Canvas canvas, Size size) {
    final color = Color.lerp(inactiveColor, activeColor, progress)!;

    // The Stroke flips to the Background Color when filled!
    final strokeColor = Color.lerp(color, activeBgColor, progress)!;

    final paintStroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 + (0.5 * progress) // Thicken slightly when active
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final paintFill = Paint()
      ..color = color.withValues(alpha: progress)
      ..style = PaintingStyle.fill;

    // Draw solid circle filling from behind
    canvas.drawCircle(const Offset(12, 12), 9, paintFill);

    canvas.save();
    canvas.translate(12, 12);
    // Clock hand spins -360 degrees
    canvas.rotate(-progress * 2.0 * math.pi);
    canvas.translate(-12, -12);

    // Clock Hands
    Path hands = Path()
      ..moveTo(12, 7)
      ..lineTo(12, 12)
      ..lineTo(15, 14);
    canvas.drawPath(hands, paintStroke);
    canvas.restore();

    // Circular arrow tracing
    Path arrow = Path()
      ..moveTo(3, 12)
      ..arcToPoint(const Offset(12, 3),
          radius: const Radius.circular(9),
          clockwise: false,
          largeArc: true)
      ..arcToPoint(const Offset(5.26, 5.74),
          radius: const Radius.circular(9.75), clockwise: false)
      ..lineTo(3, 8);

    Path arrowHead = Path()
      ..moveTo(3, 3)
      ..lineTo(3, 8)
      ..lineTo(8, 8);

    canvas.drawPath(arrow, paintStroke);
    canvas.drawPath(arrowHead, paintStroke);
  }

  @override
  bool shouldRepaint(covariant _HistoryPainter oldDelegate) =>
      oldDelegate.progress != progress;
}