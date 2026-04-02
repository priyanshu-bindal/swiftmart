import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_colors.dart';

class OrderSuccessScreen extends HookWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Current step 1: Confirming, 2: Completed, 3: Final
    final step = useState(1);

    useEffect(() {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (context.mounted) step.value = 2; // Move to Completed
      });
      Future.delayed(const Duration(milliseconds: 3500), () {
        if (context.mounted) step.value = 3; // Move to Final
      });
      return null;
    }, const []);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FF), // Soft lavender gradient background
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _buildCurrentStep(context, step.value),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context, int step) {
    switch (step) {
      case 1:
        return _buildStep1()
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutQuad);
      case 2:
        return _buildStep2()
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut);
      case 3:
      default:
        return _buildStep3(context)
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.1, curve: Curves.easeOutQuad);
    }
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey('step1'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          strokeWidth: 3,
        ),
        const SizedBox(height: 24),
        const Text(
          'Confirming your order...',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      key: const ValueKey('step2'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.check, color: AppColors.onSecondary, size: 40),
        ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
        const SizedBox(height: 24),
        const Text(
          'Order Completed!',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: AppColors.onSurface,
          ),
        ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
      ],
    );
  }

  Widget _buildStep3(BuildContext context) {
    return Stack(
      key: const ValueKey('step3'),
      children: [
        // Confetti could be added here. We'll simulate with animated scattered dots back.
        Positioned.fill(
          child: IgnorePointer(
            child: _buildConfetti(),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        // Big Circular Check
                        Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppColors.secondaryContainer, AppColors.secondary]),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: AppColors.secondary.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 12))
                              ],
                            ),
                            child: const Icon(LucideIcons.check, color: AppColors.onSecondary, size: 50),
                          ).animate().scale(curve: Curves.elasticOut, duration: 1.seconds),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Order Placed!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                            color: AppColors.onSurface,
                          ),
                        ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
                        const SizedBox(height: 8),
                        const Text(
                          'Your groceries are on the way!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ).animate().fade(delay: 300.ms).slideY(begin: 0.2),
                        const SizedBox(height: 48),

                        // Info Cards Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                LucideIcons.receipt,
                                'Order ID',
                                '#SM82910',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInfoCard(
                                LucideIcons.clock,
                                'ETA',
                                '25 mins',
                              ),
                            ),
                          ],
                        ).animate().fade(delay: 500.ms).slideY(begin: 0.1),

                        const SizedBox(height: 24),

                        // Delivery Info Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 8))
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(shape: BoxShape.circle),
                                clipBehavior: Clip.antiAlias,
                                child: CachedNetworkImage(
                                  imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB3jEqrR8k1j08E9IXXl0l3Zk2XjJv02-O5rW2rJ0I9_F9e6Jv_eD_nL5l1lW0uJbZ0D8L5nI_k0sR4iF9Ew9M0F12eI_g0i9k-W7YxH8H7L6M7h0dY14x0H9E8U6tI0N0K3s0j7xL5eWxN0l4gH1wQ0uD2M4tH8L7C4y9Q9Y7E0W3k_W8g0L0x6W9T',
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Alex is picking up your items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.star, color: Colors.amber, size: 14),
                                        const SizedBox(width: 4),
                                        const Text('4.9', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        const SizedBox(width: 4),
                                        Text('Top Rated Partner', style: TextStyle(fontSize: 10, color: AppColors.outline, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(LucideIcons.phone, color: AppColors.primary),
                            ],
                          ),
                        ).animate().fade(delay: 600.ms).slideY(begin: 0.1),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                // Buttons
                Column(
                  children: [
                    InkWell(
                      onTap: () => context.push('/order-tracking'),
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Track Order', style: TextStyle(color: AppColors.onPrimary, fontFamily: 'Manrope', fontWeight: FontWeight.w900, fontSize: 18)),
                            SizedBox(width: 8),
                            Icon(LucideIcons.mapPin, color: AppColors.onPrimary, size: 20),
                          ],
                        ),
                      ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scaleXY(end: 1.02, duration: 1.5.seconds, curve: Curves.easeInOut),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        backgroundColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      onPressed: () => context.go('/'),
                      child: const Text('Back to Home', style: TextStyle(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 16)),
                    )
                  ],
                ).animate().fade(delay: 800.ms).slideY(begin: 0.1),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onSurface)),
        ],
      ),
    );
  }

  Widget _buildConfetti() {
    return Stack(
      children: List.generate(20, (index) {
        final randomX = (index * 20).remainder(100) / 100 * 400 - 50;
        final randomY = (index * 30).remainder(100) / 100 * 600 - 100;
        return Positioned(
          left: randomX,
          top: randomY,
          child: Container(
            width: (index % 3 == 0) ? 6 : 8,
            height: (index % 3 == 0) ? 6 : 8,
            decoration: BoxDecoration(
              color: index % 2 == 0 ? AppColors.primary.withValues(alpha: 0.4) : AppColors.secondary.withValues(alpha: 0.4),
              shape: index % 4 == 0 ? BoxShape.rectangle : BoxShape.circle,
            ),
          ).animate(delay: (400 + index * 20).ms).fadeIn(duration: 600.ms).slideY(begin: 0.2, curve: Curves.easeOut),
        );
      }),
    );
  }
}
