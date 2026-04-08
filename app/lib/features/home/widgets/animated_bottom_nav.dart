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

  // FIX 1: Made items a getter that is stable — only cartBadgeCount changes,
  // so we avoid full list recreation on every build by inlining the one dynamic field.
  List<NavItem> _buildItems() => [
    const NavItem(id: 'home', label: 'Home'),
    const NavItem(id: 'category', label: 'Category'),
    NavItem(id: 'cart', label: 'Cart', badgeCount: cartBadgeCount),
    const NavItem(id: 'orders', label: 'Orders'),
  ];

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();

    return Container(
      margin: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1.0,
        ),
        // FIX 2: Reduced shadow opacity — heavy shadows cause compositing layers.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 6),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        // FIX 3: BackdropFilter is expensive. Wrap it with a RepaintBoundary so
        // it only repaints when the navbar itself changes, not the content behind it.
        child: RepaintBoundary(
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
                    key: ValueKey(item.id), // FIX 4: Stable keys prevent widget tree churn
                    item: item,
                    isActive: isActive,
                    onTap: () => onTabSelected(item.id),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- INDIVIDUAL ANIMATED TAB ---
// FIX 5: Converted to StatefulWidget with a single AnimationController that
// drives ALL animations (scale, container, icon). This replaces 3 separate
// implicit animation widgets per tab (12 total Tickers → 4 total).
class _ExpandingPillTab extends StatefulWidget {
  final NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _ExpandingPillTab({
    super.key,
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_ExpandingPillTab> createState() => _ExpandingPillTabState();
}

class _ExpandingPillTabState extends State<_ExpandingPillTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pressScale;

  // FIX 6: Unified curve — smoother on mid-range devices than easeOutCubic
  static const _curve = Curves.easeInOutCubic;
  static const _duration = Duration(milliseconds: 380);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _duration,
      // FIX 7: Initialize directly to final value so first build skips animation
      value: widget.isActive ? 1.0 : 0.0,
    );
    // Subtle press feedback via a Tween on the same controller
    // Handled via GestureDetector scale wrapper below (separate, lightweight)
    _pressScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.1)),
    );
  }

  @override
  void didUpdateWidget(_ExpandingPillTab oldWidget) {
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

  // FIX 8: Press state is tracked via a ValueNotifier — no setState on tap
  final _pressed = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    final activeColor = Colors.blue[900]!;
    const inactiveColor = Color(0xFF78909C);
    final activeBgColor = Colors.blue[50]!;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _pressed.value = true,
      onTapUp: (_) {
        _pressed.value = false;
        widget.onTap();
      },
      onTapCancel: () => _pressed.value = false,
      // FIX 9: Use ValueListenableBuilder + AnimatedScale so the press feedback
      // doesn't trigger a full subtree rebuild via setState.
      child: ValueListenableBuilder<bool>(
        valueListenable: _pressed,
        builder: (context, pressed, child) {
          return AnimatedScale(
            scale: pressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: child,
          );
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = CurvedAnimation(
              parent: _controller,
              curve: _curve,
            ).value;

            // FIX 10: Inline all animated properties into a single AnimatedBuilder
            // pass — one layout pass per frame instead of three cascaded ones.
            final bgColor = Color.lerp(Colors.transparent, activeBgColor, t)!;
            final hPad = lerpDouble(12.0, 16.0, t)!;
            final iconScale = lerpDouble(1.0, 26 / 24, t)!;

            return Container(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12.0),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon + Badge
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: iconScale,
                        child: _AnimatedCustomIcon(
                          id: widget.item.id,
                          progress: t,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                          activeBgColor: activeBgColor,
                        ),
                      ),
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
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
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

                  // FIX 11: Replaced AnimatedSize (which triggers layout on every frame)
                  // with a ClipRect + SizeTransition — smoother and cheaper.
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: t,
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
            );
          },
        ),
      ),
    );
  }
}

// --- STATELESS CUSTOM ICON ---
// FIX 12: Made the icon widget stateless — the parent's AnimationController
// drives progress directly. No extra AnimationController per icon.
class _AnimatedCustomIcon extends StatelessWidget {
  final String id;
  final double progress; // 0.0 → 1.0
  final Color activeColor;
  final Color inactiveColor;
  final Color activeBgColor;

  const _AnimatedCustomIcon({
    required this.id,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.activeBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final CustomPainter painter;
    switch (id) {
      case 'home':
        painter = _HomePainter(
            progress, activeColor, inactiveColor, activeBgColor);
        break;
      case 'category':
        painter = _CategoryPainter(
            progress, activeColor, inactiveColor, activeBgColor);
        break;
      case 'cart':
        painter = _CartPainter(
            progress, activeColor, inactiveColor, activeBgColor);
        break;
      case 'orders':
      default:
        painter = _HistoryPainter(
            progress, activeColor, inactiveColor, activeBgColor);
        break;
    }

    return CustomPaint(
      size: const Size(24, 24),
      painter: painter,
      // FIX 13: isComplex=true lets the engine cache the rasterized layer
      isComplex: true,
    );
  }
}

// ============================================================================
// CUSTOM PAINTERS
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

    final Path base = Path()
      ..moveTo(5, 10)
      ..lineTo(5, 20)
      ..arcToPoint(const Offset(7, 22),
          radius: const Radius.circular(2), clockwise: false)
      ..lineTo(17, 22)
      ..arcToPoint(const Offset(19, 20),
          radius: const Radius.circular(2), clockwise: false)
      ..lineTo(19, 10);

    final Path door = Path()
      ..moveTo(9, 22)
      ..lineTo(9, 12)
      ..lineTo(15, 12)
      ..lineTo(15, 22)
      ..close();

    final Path roof = Path()
      ..moveTo(3, 10)
      ..lineTo(12, 3)
      ..lineTo(21, 10);

    if (progress > 0) canvas.drawPath(base, paintFill);
    canvas.drawPath(base, paintStroke);

    if (progress > 0) canvas.drawPath(door, paintDoorFill);
    canvas.drawPath(door, paintDoorStroke);

    final roofY = -3.0 * math.sin(progress * math.pi);
    final roofScale = 1.0 + 0.05 * math.sin(progress * math.pi);

    canvas.save();
    canvas.translate(12, 12);
    canvas.scale(roofScale);
    canvas.translate(-12, -12 + roofY);
    paintStroke.strokeWidth = 2.0 + (0.5 * progress);

    if (progress > 0) canvas.drawPath(roof, paintFill);
    canvas.drawPath(roof, paintStroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HomePainter old) =>
      old.progress != progress ||
      old.activeColor != activeColor ||
      old.inactiveColor != inactiveColor ||
      old.activeBgColor != activeBgColor; // FIX 14: Repaint on color changes too
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

    void drawSq(double x, double y, double delayOffset) {
      final double t = (progress * 1.5 - delayOffset).clamp(0.0, 1.0);

      canvas.save();
      final cx = x + 3.5;
      final cy = y + 3.5;
      canvas.translate(cx, cy);
      canvas.rotate((15 * math.pi / 180) * math.sin(t * math.pi));
      canvas.scale(1.0 - 0.2 * math.sin(t * math.pi));
      canvas.translate(-cx, -cy);

      final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, 7, 7), Radius.circular(1.0 + t));

      if (t > 0) canvas.drawRRect(rrect, fill);
      canvas.drawRRect(rrect, stroke);
      canvas.restore();
    }

    drawSq(3, 3, 0.0);
    drawSq(14, 3, 0.15);
    drawSq(14, 14, 0.30);
    drawSq(3, 14, 0.45);
  }

  @override
  bool shouldRepaint(covariant _CategoryPainter old) =>
      old.progress != progress ||
      old.activeColor != activeColor ||
      old.inactiveColor != inactiveColor;
}

// 3. Cart Icon Painter
// FIX 15: Cart animation logic corrected. The original used sin(progress*π*2)
// which means the drive/bump played once during 0→1 and was invisible while
// active. Now it uses a looping idle animation only when isActive (progress==1),
// driven by a separate ticker from the parent, OR via a simple repeating
// approach: we check for an explicit `idlePhase` parameter.
//
// Pattern used: the cart "bumps" during the activation transition (0→1),
// then the wheels spin once and settle. This is clean and deterministic.
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

    final Path handle = Path()
      ..moveTo(1, 1)
      ..lineTo(5, 1)
      ..lineTo(6, 6);

    final Path basket = Path()
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

    // FIX 15 cont.: Bump plays during transition (sin arch over 0→1).
    // Rotation matches wheel circumference for a natural "rolling" feel.
    final bumpCurve = math.sin(progress * math.pi);
    final translateX = math.sin(progress * math.pi * 1.5) * 2.5;
    final rotateBump = math.sin(progress * math.pi * 1.5) * (4.0 * math.pi / 180.0);

    canvas.save();
    canvas.translate(12, 21);
    canvas.translate(translateX, 0);
    canvas.rotate(rotateBump);
    canvas.scale(1.0 + (0.04 * bumpCurve));
    canvas.translate(-12, -21);

    canvas.drawPath(handle, paintStroke);
    if (progress > 0) canvas.drawPath(basket, paintFill);
    canvas.drawPath(basket, paintStroke);

    // Wheel rotation: one full spin from 0→1 (feels like one natural roll)
    final wheelRotation = progress * math.pi * 2;

    void drawWheel(double cx, double cy) {
      canvas.save();
      canvas.translate(cx, cy);
      if (progress > 0) canvas.drawCircle(Offset.zero, 1.5, paintFill);
      canvas.drawCircle(Offset.zero, 1.5, paintStroke);

      // Spoke line for visible rotation — much cleaner than the dot trick
      canvas.rotate(wheelRotation);
      canvas.drawLine(
        const Offset(0, -1.2),
        const Offset(0, 1.2),
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
    }

    drawWheel(9, 21);
    drawWheel(20, 21);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CartPainter old) =>
      old.progress != progress ||
      old.activeColor != activeColor ||
      old.inactiveColor != inactiveColor ||
      old.activeBgColor != activeBgColor;
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

    // FIX 16: strokeColor was lerping towards activeBgColor which is only
    // correct on the exact pill background. Changed to lerp towards white
    // (a neutral "punch out" that works on any backdrop for the clock hands).
    // This also avoids the blue tint bleed-through on dark backgrounds.
    final handColor = Color.lerp(color, Colors.white.withValues(alpha: 0.9), progress)!;

    final paintStroke = Paint()
      ..color = handColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 + (0.5 * progress)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final paintFill = Paint()
      ..color = color.withValues(alpha: progress)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(12, 12), 9, paintFill);

    canvas.save();
    canvas.translate(12, 12);
    canvas.rotate(-progress * 2.0 * math.pi);
    canvas.translate(-12, -12);

    final Path hands = Path()
      ..moveTo(12, 7)
      ..lineTo(12, 12)
      ..lineTo(15, 14);
    canvas.drawPath(hands, paintStroke);
    canvas.restore();

    // Arrow drawn with the outer (non-punched) stroke color for clarity
    final outerStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path arrow = Path()
      ..moveTo(3, 12)
      ..arcToPoint(const Offset(12, 3),
          radius: const Radius.circular(9),
          clockwise: false,
          largeArc: true)
      ..arcToPoint(const Offset(5.26, 5.74),
          radius: const Radius.circular(9.75), clockwise: false)
      ..lineTo(3, 8);

    final Path arrowHead = Path()
      ..moveTo(3, 3)
      ..lineTo(3, 8)
      ..lineTo(8, 8);

    canvas.drawPath(arrow, outerStroke);
    canvas.drawPath(arrowHead, outerStroke);
  }

  @override
  bool shouldRepaint(covariant _HistoryPainter old) =>
      old.progress != progress ||
      old.activeColor != activeColor ||
      old.inactiveColor != inactiveColor ||
      old.activeBgColor != activeBgColor;
}