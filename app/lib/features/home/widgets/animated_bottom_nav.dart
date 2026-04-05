import 'dart:ui';
import 'package:flutter/material.dart';

// --- DATA MODEL ---
class NavItem {
  final String id;
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final int badgeCount;

  const NavItem({
    required this.id,
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    this.badgeCount = 0,
  });
}

// --- THE NAVBAR WIDGET ---
class SwiftmartBottomNav extends StatelessWidget {
  final String currentTab;
  final ValueChanged<String> onTabSelected;

  const SwiftmartBottomNav({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  // Navigation Items matching the React Canvas
  static const List<NavItem> items = [
    NavItem(
      id: 'home',
      label: 'Home',
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
    ),
    NavItem(
      id: 'category',
      label: 'Category',
      activeIcon: Icons.grid_view_rounded,
      inactiveIcon: Icons.grid_view_outlined,
    ),
    NavItem(
      id: 'orders',
      label: 'Orders',
      activeIcon: Icons.inventory_2_rounded,
      inactiveIcon: Icons.inventory_2_outlined,
    ),
    NavItem(
      id: 'cart',
      label: 'Cart',
      activeIcon: Icons.shopping_cart_rounded,
      inactiveIcon: Icons.shopping_cart_outlined,
      badgeCount: 3, 
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      // Shadow applied outside the clip so it doesn't get cut off
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -10),
            blurRadius: 40,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            color: Colors.white.withValues(alpha: 0.9),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              // Accommodate for iOS home indicator
              bottom: MediaQuery.of(context).padding.bottom + 16, 
            ),
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
    // Colors mapped directly from your React Tailwind canvas
    const activeColor = Color(0xFF4F46E5);    // indigo-600
    const inactiveColor = Color(0xFF94A3B8);  // slate-400
    const activeBgColor = Color(0xFFEEF2FF);  // indigo-50

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
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                    child: Icon(
                      widget.isActive ? widget.item.activeIcon : widget.item.inactiveIcon,
                      key: ValueKey(widget.isActive),
                      color: widget.isActive ? activeColor : inactiveColor,
                      size: widget.isActive ? 26 : 24, // Replicates "scale-110"
                    ),
                  ),
                  
                  // Hide badge when active or when count is 0
                  if (widget.item.badgeCount > 0 && !widget.isActive)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          widget.item.badgeCount > 99 ? '99+' : '${widget.item.badgeCount}',
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
                      style: const TextStyle(
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