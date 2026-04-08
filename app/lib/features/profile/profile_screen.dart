import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../auth/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final userName = user != null && user.displayName.isNotEmpty
        ? user.displayName
        : 'Priyanshu Bindal';
    final userEmail = user != null && (user.email?.isNotEmpty ?? false)
        ? user.email!
        : 'priyanshu.bindal@premium.com';
    final cashbackAmount = "250"; // dynamic fallback mockup

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: AppColors.background.withValues(alpha: 0.75),
              elevation: 0,
              centerTitle: true,
              scrolledUnderElevation: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.onSurfaceVariant,
                ),
                onPressed: () {
                  if (context.canPop()) context.pop();
                },
              ),
              title: Text(
                'Profile',
                style: GoogleFonts.manrope(
                  color: AppColors.onBackground,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: AppColors.onSurfaceVariant,
                  ),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
          left: 24,
          right: 24,
          bottom: 48,
        ),
        child: Column(
          children: [
            // Profile Header Section
            Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surfaceContainerHigh,
                          width: 2,
                        ),
                        image: const DecorationImage(
                          image: NetworkImage(
                            "https://source.unsplash.com/featured/?shopping",
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: AppColors.onPrimary,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  userName,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.outline,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: const BorderSide(
                      color: AppColors.outlineVariant,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    foregroundColor: AppColors.onSurfaceVariant,
                    textStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Edit Profile'),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Quick Action Grid
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.receipt_long,
                    iconColor: AppColors.primary,
                    iconBg: AppColors.primaryFixed,
                    label: 'My Orders',
                    onTap: () => context.push('/order-history'),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.account_balance_wallet,
                    iconColor: AppColors.secondary,
                    iconBg: AppColors.secondaryContainer,
                    label: 'Wallet',
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.local_offer,
                    iconColor: AppColors.tertiary,
                    iconBg: AppColors.tertiaryFixed,
                    label: 'Offers',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.location_on,
                    iconColor: AppColors.outline,
                    iconBg: AppColors.surfaceContainerHighest,
                    label: 'Addresses',
                    onTap: () {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Wallet Spotlight Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryContainer],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EXCLUSIVE REWARD',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                color: AppColors.primaryFixed.withValues(
                                  alpha: 0.9,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹$cashbackAmount Cashback Available',
                              style: GoogleFonts.manrope(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: AppColors.onPrimary,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.stars,
                          color: AppColors.onPrimary,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Settings List
            _SettingsSection(
              title: 'Account Details',
              items: [
                _SettingsItem(
                  icon: Icons.person,
                  iconColor: AppColors.primary,
                  label: 'Personal Information',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.location_on,
                  iconColor: AppColors.primary,
                  label: 'Saved Addresses',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.credit_card,
                  iconColor: AppColors.primary,
                  label: 'Payment Methods',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 40),

            _SettingsSection(
              title: 'App Preferences',
              items: [
                _SettingsItem(
                  icon: Icons.notifications_active,
                  iconColor: AppColors.secondary,
                  label: 'Notifications',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.dark_mode,
                  iconColor: AppColors.secondary,
                  label: 'Dark Mode',
                  isToggle: true,
                  toggleValue: false,
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.translate,
                  iconColor: AppColors.secondary,
                  label: 'Language',
                  trailingText: 'English',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 40),

            _SettingsSection(
              title: 'Support',
              items: [
                _SettingsItem(
                  icon: Icons.support_agent,
                  iconColor: AppColors.tertiary,
                  label: 'Help & Support',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.info,
                  iconColor: AppColors.tertiary,
                  label: 'About SwiftMart',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Logout Button
            InkWell(
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(
                      'Log Out',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
                    ),
                    content: Text(
                      'Are you sure you want to log out?',
                      style: GoogleFonts.inter(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            color: AppColors.outline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Log Out',
                          style: GoogleFonts.inter(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await const FlutterSecureStorage().deleteAll();
                  await ref.read(authProvider.notifier).signOut();
                }
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout, color: AppColors.error, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Log Out',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.onBackground.withValues(alpha: 0.04),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: AppColors.outline.withValues(alpha: 0.8),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool isToggle;
  final bool toggleValue;
  final String? trailingText;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.isToggle = false,
    this.toggleValue = false,
    this.trailingText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isToggle ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            if (isToggle)
              Switch(
                value: toggleValue,
                onChanged: (val) {},
                activeTrackColor: AppColors.primary,
              )
            else if (trailingText != null)
              Row(
                children: [
                  Text(
                    trailingText!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.outline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: AppColors.outline),
                ],
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}
