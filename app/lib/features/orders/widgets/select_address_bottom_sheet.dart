import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/models/address_model.dart';
import '../../profile/providers/address_provider.dart';

class SelectAddressBottomSheet extends HookConsumerWidget {
  const SelectAddressBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressListProvider);
    final currentSelected = ref.watch(selectedAddressProvider);
    final localSelected = useState<String?>(currentSelected?.id);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ─────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Title + close ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Select Address',
                    style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: AppColors.onSurface)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.x,
                        size: 16, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Address list ────────────────────────────────────────────
          Expanded(
            child: addressesAsync.when(
              loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.skyBlue)),
              error: (e, _) =>
                  Center(child: Text('Error: $e')),
              data: (addresses) {
                if (addresses.isEmpty) {
                  return _emptyView(context, ref);
                }
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    ...addresses.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final addr = entry.value;
                      final isSelected = localSelected.value == addr.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AddressCard(
                          address: addr,
                          isSelected: isSelected,
                          onTap: () => localSelected.value = addr.id,
                        )
                            .animate(delay: (60 * idx).ms)
                            .fadeIn(duration: 250.ms)
                            .slideY(begin: 0.06),
                      );
                    }),
                    // ── Add New Address ─────────────────────────────────
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/add-address');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.skyBlue.withValues(alpha: 0.4),
                            width: 1.5,
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.plusCircle,
                                color: AppColors.skyBlue, size: 20),
                            const SizedBox(width: 8),
                            Text('Add New Address',
                                style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.skyBlue,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),

          // ── Use This Address button ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    final addresses =
                        addressesAsync.asData?.value ?? [];
                    final selected = addresses
                        .where((a) => a.id == localSelected.value)
                        .firstOrNull;
                    if (selected != null) {
                      ref.read(selectedAddressProvider.notifier).state =
                          selected;
                    }
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.skyBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Use This Address',
                      style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.white)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _emptyView(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.mapPin, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('No saved addresses',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.push('/add-address');
            },
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add Address'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.skyBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Address card ──────────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final bool isSelected;
  final VoidCallback onTap;

  const _AddressCard({
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (address.label.toLowerCase()) {
      case 'home':
        return LucideIcons.home;
      case 'work':
        return LucideIcons.briefcase;
      default:
        return LucideIcons.mapPin;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.skyBlue.withValues(alpha: 0.04)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.skyBlue : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.skyBlue.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon,
                  size: 18,
                  color:
                      isSelected ? AppColors.skyBlue : Colors.grey.shade600),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(address.label,
                          style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.onSurface)),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warmOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('DEFAULT',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.warmOrange,
                                  letterSpacing: 0.8)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.formattedAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Radio
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.skyBlue : Colors.grey.shade300,
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
