import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../providers/auth_provider.dart';

class GoogleSignInButton extends ConsumerWidget {
  const GoogleSignInButton({
    super.key,
    required this.onError,
    this.enabled = true,
  });

  final void Function(String message) onError;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: !enabled
          ? null
          : () async {
              await ref.read(authProvider.notifier).signInWithGoogle();
              final s = ref.read(authProvider);
              if (s.status == AuthStatus.error && s.errorMessage != null) {
                onError(s.errorMessage!);
              }
            },
      icon: const Icon(LucideIcons.chrome, color: Colors.blue),
      label: const Text('Continue with Google'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
