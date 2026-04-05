import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class AnimatedSearchBar extends HookWidget {
  const AnimatedSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Style Constants matching prompt exactly
    const Color bgSurface =
        Colors.white; // Changed from bgLavender to give it high contrast
    const Color primaryViolet = Color(0xFF6C3CE1);
    const Color accentTeal = Color(0xFF00D4AA);

    // Contextual Data Generation
    final timeContext = useMemoized(() {
      final hour = DateTime.now().hour;
      if (hour >= 5 && hour < 12) return 'Search for breakfast items ☀️';
      if (hour >= 12 && hour < 17) return 'Find lunch essentials fast 🍱';
      if (hour >= 17 && hour < 21) return 'OrderModel snacks & beverages 🍿';
      return 'Late night cravings? OrderModel now 🌙';
    });

    final placeholders = useMemoized(
      () => [
        timeContext,
        'Search for milk, bread, eggs...',
        'Find fruits, vegetables, snacks...',
        'OrderModel fresh groceries in minutes ⚡',
        'Get daily essentials fast',
        'Search & save with coupons 🎉',
        'Flash deals ending soon 🔥',
      ],
    );

    // Hooks State
    final currentIndex = useState(0);
    final isFocused = useState(false);
    final hasText = useState(false);

    // Controllers
    final focusNode = useFocusNode();
    final textController = useTextEditingController();
    final scaleController = useAnimationController(
      duration: const Duration(milliseconds: 150),
    );
    final scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: scaleController, curve: Curves.easeOut));

    // Listeners and Timers
    useEffect(() {
      void focusListener() {
        isFocused.value = focusNode.hasFocus;
      }

      focusNode.addListener(focusListener);

      void textListener() {
        hasText.value = textController.text.isNotEmpty;
      }

      textController.addListener(textListener);

      // Loop Timer for 3 seconds interval
      Timer? timer;
      if (!isFocused.value) {
        // Pause animation on focus
        timer = Timer.periodic(const Duration(seconds: 3), (t) {
          currentIndex.value = (currentIndex.value + 1) % placeholders.length;
        });
      }

      return () {
        focusNode.removeListener(focusListener);
        textController.removeListener(textListener);
        timer?.cancel();
      };
    }, [isFocused.value]);

    return GestureDetector(
      onTapDown: (_) => scaleController.forward(),
      onTapUp: (_) => scaleController.reverse(),
      onTapCancel: () => scaleController.reverse(),
      onTap: () => context.push('/search'),
      child: ScaleTransition(
        scale: scaleAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: bgSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isFocused.value
                    ? primaryViolet.withValues(alpha: 0.6)
                    : Colors.grey.withValues(alpha: 0.1),
                width: isFocused.value
                    ? 2
                    : 1, // Glow effect simulation via Border
              ),
              boxShadow: [
                BoxShadow(
                  color: isFocused.value
                      ? primaryViolet.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: isFocused.value ? 20 : 12,
                  spreadRadius: isFocused.value ? 2 : 0,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: isFocused.value ? primaryViolet : Colors.grey.shade500,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Animated Placeholder (Only visible if no text typed)
                      if (!hasText.value)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                                // Slide from bottom-up effect coupled with Fade
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.0, 0.4),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                          child: Text(
                            placeholders[currentIndex.value],
                            key: ValueKey<int>(currentIndex.value),
                            style: GoogleFonts.inter(
                              color:
                                  placeholders[currentIndex.value].startsWith(
                                    'Trending:',
                                  )
                                  ? primaryViolet
                                  : Colors.grey.shade500,
                              fontWeight:
                                  placeholders[currentIndex.value].startsWith(
                                    'Trending:',
                                  )
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      // Actual Input Field (Cursor and typing happen over the placeholder until text is typed)
                      TextField(
                        controller: textController,
                        focusNode: focusNode,
                        readOnly: true,
                        onTap: () {
                          context.push('/search');
                        },
                        style: GoogleFonts.inter(
                          color: const Color(
                            0xFF1A1B21,
                          ), // AppColors.onSurface approximation for standalone
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        cursorColor: accentTeal,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
                // Mic Icon acting as the Accent interaction
                if (!hasText.value)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryViolet.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: primaryViolet,
                      size: 20,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () {
                      textController.clear();
                      focusNode.unfocus();
                    },
                    child: const Icon(
                      Icons.close,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
