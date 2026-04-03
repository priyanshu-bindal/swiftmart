import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/models/address_model.dart';
import '../../../../core/services/supabase_service.dart';

class AddressesRepository {
  Future<List<AddressModel>> getAddresses() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    final data = await SupabaseService.client
        .from(SupabaseConstants.addressesTable)
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false);

    return data.map((e) => AddressModel.fromJson(e)).toList();
  }

  Future<void> addAddress(AddressModel address) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception("User not logged in");

    // Override user id
    final data = address.toJson();
    data['user_id'] = userId;
    
    // Remove if empty since it's auto generated
    if (data['id'] == '') {
      data.remove('id');
    }

    await SupabaseService.client
        .from(SupabaseConstants.addressesTable)
        .insert(data);
  }

  Future<void> deleteAddress(String id) async {
    await SupabaseService.client
        .from(SupabaseConstants.addressesTable)
        .delete()
        .eq('id', id);
  }

  Future<void> setDefault(String id) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception("User not logged in");

    // First reset all to false
    await SupabaseService.client
        .from(SupabaseConstants.addressesTable)
        .update({'is_default': false})
        .eq('user_id', userId);

    // Set the specific one to true
    await SupabaseService.client
        .from(SupabaseConstants.addressesTable)
        .update({'is_default': true})
        .eq('id', id);
  }
}
