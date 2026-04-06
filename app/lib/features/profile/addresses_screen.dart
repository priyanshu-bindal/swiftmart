import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async' show unawaited;

import '../../core/theme/app_colors.dart';
import '../../core/models/address_model.dart';
import 'providers/address_provider.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressListProvider);

    return Scaffold(
      backgroundColor: AppColors.cleanBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cleanBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Saved Addresses',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plusCircle, color: AppColors.skyBlue),
            onPressed: () => context.push('/add-address'),
            tooltip: 'Add Address',
          ),
        ],
      ),
      body: addressesAsync.when(
        data: (addresses) {
          if (addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.mapPinOff,
                    size: 72,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No addresses saved',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a delivery address to get started.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.push('/add-address'),
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
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: addresses.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == addresses.length) {
                return TextButton.icon(
                  onPressed: () => context.push('/add-address'),
                  icon: const Icon(LucideIcons.plusCircle, size: 18),
                  label: const Text('Add New Address'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.skyBlue,
                  ),
                );
              }
              final addr = addresses[index];
              final isDefault = addr.isDefault;
              return _AddressCard(
                    address: addr,
                    isDefault: isDefault,
                    onSetDefault: () =>
                        _setDefault(context, ref, addr.id),
                    onDelete: () =>
                        _deleteAddress(context, ref, addr.id),
                  )
                  .animate(delay: Duration(milliseconds: 60 * index))
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.06, end: 0, curve: Curves.easeOut);
            },
          );
        },
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Future<void> _setDefault(
    BuildContext context,
    WidgetRef ref,
    String addressId,
  ) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await Supabase.instance.client
          .from('addresses')
          .update({'is_default': false})
          .eq('user_id', uid);
      await Supabase.instance.client
          .from('addresses')
          .update({'is_default': true})
          .eq('id', addressId);
      unawaited(ref.refresh(addressListProvider.future));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set default: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAddress(
    BuildContext context,
    WidgetRef ref,
    String addressId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Supabase.instance.client
          .from('addresses')
          .delete()
          .eq('id', addressId);
      unawaited(ref.refresh(addressListProvider.future));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ── Address Card ──────────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final bool isDefault;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.isDefault,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDefault
            ? Border.all(color: AppColors.skyBlue, width: 2)
            : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _iconForType(address.label),
                  color: isDefault ? AppColors.skyBlue : Colors.grey.shade500,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  address.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warmOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'DEFAULT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: AppColors.warmOrange,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              address.formattedAddress,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isDefault)
                  TextButton(
                    onPressed: onSetDefault,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.skyBlue,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Set as Default',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  tooltip: 'Delete',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'home':
        return LucideIcons.home;
      case 'work':
      case 'office':
        return LucideIcons.briefcase;
      default:
        return LucideIcons.mapPin;
    }
  }
}
