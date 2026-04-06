import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/core/models/address_model.dart';

/// Fetches all addresses for the currently authenticated user.
final addressListProvider =
    FutureProvider.autoDispose<List<AddressModel>>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return [];
  try {
    final data = await Supabase.instance.client
        .from('addresses')
        .select()
        .eq('user_id', uid)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, st) {
    debugPrint('addressListProvider error: $e\n$st');
    return [];
  }
});

/// Currently-selected address (for checkout).
/// Initialized to the default address when addresses load.
final selectedAddressProvider = StateProvider<AddressModel?>((ref) {
  final addresses = ref.watch(addressListProvider).asData?.value ?? [];
  if (addresses.isEmpty) return null;
  // Pick the default address, or fallback to first
  return addresses.firstWhere(
    (a) => a.isDefault,
    orElse: () => addresses.first,
  );
});
