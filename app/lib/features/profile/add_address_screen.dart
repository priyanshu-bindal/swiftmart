import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import 'providers/address_provider.dart';

class AddAddressScreen extends HookConsumerWidget {
  const AddAddressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final flatNoCtrl = useTextEditingController();
    final floorCtrl = useTextEditingController();
    final buildingCtrl = useTextEditingController();
    final areaCtrl = useTextEditingController();
    final landmarkCtrl = useTextEditingController();
    final selectedLabel = useState('Home');
    final saving = useState(false);

    // Map center (default: Mumbai)
    final mapCenter = useState(const LatLng(19.0760, 72.8777));

    Future<void> saveAddress() async {
      if (!formKey.currentState!.validate()) return;

      saving.value = true;
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) {
        saving.value = false;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Not authenticated'),
                backgroundColor: AppColors.error),
          );
        }
        return;
      }

      try {
        final fullAddr = [
          flatNoCtrl.text.trim(),
          if (floorCtrl.text.trim().isNotEmpty) floorCtrl.text.trim(),
          buildingCtrl.text.trim(),
          areaCtrl.text.trim(),
        ].join(', ');

        await Supabase.instance.client.from('addresses').insert({
          'user_id': uid,
          'label': selectedLabel.value,
          'flat_no': flatNoCtrl.text.trim(),
          'floor': floorCtrl.text.trim(),
          'building_name': buildingCtrl.text.trim(),
          'area': areaCtrl.text.trim(),
          'landmark': landmarkCtrl.text.trim(),
          'full_address': fullAddr,
          'lat': mapCenter.value.latitude,
          'lng': mapCenter.value.longitude,
          'is_default': false,
        });

        ref.invalidate(addressListProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Address saved successfully!'),
                backgroundColor: Color(0xFF22C55E)),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to save: $e'),
                backgroundColor: AppColors.error),
          );
        }
      } finally {
        saving.value = false;
      }
    }

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
        title: const Text('Add New Address',
            style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: AppColors.onSurface)),
        centerTitle: false,
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            // ── Map widget ──────────────────────────────────────────
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: mapCenter.value,
                      initialZoom: 15,
                      onTap: (tapPos, point) {
                        mapCenter.value = point;
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.swiftmart.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: mapCenter.value,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_pin,
                              color: AppColors.skyBlue,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Pinned location chip
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 6),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.mapPin,
                              size: 14, color: AppColors.skyBlue),
                          const SizedBox(width: 4),
                          const Text('Pinned Location',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            // ── Form fields ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _InputField(
                    controller: flatNoCtrl,
                    label: 'Flat / House No *',
                    isRequired: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InputField(
                    controller: floorCtrl,
                    label: 'Floor (Optional)',
                  ),
                ),
              ],
            ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 14),

            _InputField(
              controller: buildingCtrl,
              label: 'Building / Apartment Name *',
              isRequired: true,
            ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 14),

            _InputField(
              controller: areaCtrl,
              label: 'Area / Sector / Locality *',
              isRequired: true,
              suffixIcon: LucideIcons.search,
            ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 14),

            _InputField(
              controller: landmarkCtrl,
              label: 'Nearby Landmark (Optional)',
            ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 28),

            // ── Save as ─────────────────────────────────────────────
            const Text('Save Address As',
                    style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.onSurface))
                .animate(delay: 300.ms)
                .fadeIn()
                .slideY(begin: 0.1),
            const SizedBox(height: 12),

            Row(
              children: [
                _LabelChip(
                  label: 'Home',
                  icon: LucideIcons.home,
                  isSelected: selectedLabel.value == 'Home',
                  onTap: () => selectedLabel.value = 'Home',
                ),
                const SizedBox(width: 10),
                _LabelChip(
                  label: 'Work',
                  icon: LucideIcons.briefcase,
                  isSelected: selectedLabel.value == 'Work',
                  onTap: () => selectedLabel.value = 'Work',
                ),
                const SizedBox(width: 10),
                _LabelChip(
                  label: 'Other',
                  icon: LucideIcons.mapPin,
                  isSelected: selectedLabel.value == 'Other',
                  onTap: () => selectedLabel.value = 'Other',
                ),
              ],
            ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 24),

            // ── Info banner ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.skyBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.skyBlue.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.info,
                      size: 20, color: AppColors.skyBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Adding your address precisely helps our delivery partners bring your order right to your door.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1),
          ],
        ),
      ),

      // ── Save button ─────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: saving.value ? null : saveAddress,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.skyBlue,
                disabledBackgroundColor:
                    AppColors.skyBlue.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: saving.value
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Save Address',
                            style: TextStyle(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Colors.white)),
                        SizedBox(width: 6),
                        Icon(LucideIcons.chevronRight,
                            size: 18, color: Colors.white),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Input field ──────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isRequired;
  final IconData? suffixIcon;

  const _InputField({
    required this.controller,
    required this.label,
    this.isRequired = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: isRequired
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, size: 18, color: Colors.grey.shade400)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.skyBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ── Label chip ───────────────────────────────────────────────────────────────

class _LabelChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _LabelChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.skyBlue : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.skyBlue : Colors.grey.shade300,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                  color: AppColors.skyBlue.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isSelected ? Colors.white : Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}
