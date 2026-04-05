import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/cart_toast_provider.dart';
import 'app_network_image.dart';

/// Floating animated "Item Added" confirmation bar.
/// Drop this into a [Stack] above the main content. It listens to
/// [cartToastProvider] and animates itself in/out automatically.
///
/// [bottomOffset] controls how far above the bottom the bar floats.
/// Use 90 inside MainShell (above nav), 24 on full-screen pages.
class CartToastBar extends ConsumerStatefulWidget {
  final double bottomOffset;
  const CartToastBar({super.key, this.bottomOffset = 90});

  @override
  ConsumerState<CartToastBar> createState() => _CartToastBarState();
}

class _CartToastBarState extends ConsumerState<CartToastBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6)),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateIn() {
    if (_isVisible) {
      // Already visible — just replay scale to signal update
      _controller.forward(from: 0.7);
    } else {
      _isVisible = true;
      _controller.forward(from: 0);
    }
  }

  void _animateOut() {
    _controller
        .reverse()
        .then((_) => setState(() => _isVisible = false));
  }

  @override
  Widget build(BuildContext context) {
    final toast = ref.watch(cartToastProvider);

    // React to state changes
    ref.listen<CartToastState>(cartToastProvider, (prev, next) {
      if (next.visible && !(prev?.visible ?? false)) {
        _animateIn();
      } else if (!next.visible && (prev?.visible ?? false)) {
        _animateOut();
      } else if (next.visible && (prev?.visible ?? false) &&
          next.totalItemsJustAdded != (prev?.totalItemsJustAdded ?? 0)) {
        // Count updated — re-animate to signal the update
        _animateIn();
      }
    });

    if (!_isVisible && !toast.visible) return const SizedBox.shrink();

    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = isLight ? Colors.white : const Color(0xFF1E1E1E);
    final textColor = isLight ? const Color(0xFF1A1A1A) : Colors.white;
    final count = toast.totalItemsJustAdded;

    return Positioned(
      left: 16,
      right: 16,
      bottom: widget.bottomOffset,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 50) {
            ref.read(cartToastProvider.notifier).dismiss();
          }
        },
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(20),
                shadowColor: Colors.black.withValues(alpha: 0.18),
                color: bg,
                child: Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // ── Left: Check + thumbnail + label ──────────────────
                      _buildCheckmark(),
                      const SizedBox(width: 10),
                      if (toast.productImage != null) ...[
                        _buildThumbnail(toast.productImage!),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              count == 1 ? '1 item added' : '$count items added',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              toast.productName,
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.55),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // ── Right: View Cart CTA ──────────────────────────────
                      _buildViewCartButton(context, ref),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckmark() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Color(0xFF2E7D32),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildThumbnail(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AppNetworkImage(
        imageUrl: imageUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        placeholder: (ctx, url) => Container(
          width: 40,
          height: 40,
          color: const Color(0xFFF4F4F4),
        ),
        errorWidget: (ctx, url, err) => Container(
          width: 40,
          height: 40,
          color: const Color(0xFFF4F4F4),
          child: const Icon(Icons.image_not_supported, size: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildViewCartButton(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(cartToastProvider.notifier).dismiss();
        context.push('/cart');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 14),
            SizedBox(width: 5),
            Text(
              'View Cart',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
