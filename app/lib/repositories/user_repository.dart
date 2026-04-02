import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/providers/supabase_provider.dart';
import '../models/user_profile.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return UserRepository(supabase: supabase);
});

class UserRepository {
  final SupabaseClient supabase;

  UserRepository({required this.supabase});

  String _getUid() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not authenticated");
    return user.uid;
  }

  Future<void> createProfile({
    required String name,
    required String email,
    String locationName = 'Set location',
    double? lat,
    double? lng,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    await supabase.from('users').upsert({
      'id': uid,
      'name': name,
      'email': email,
      'location_name': locationName,
      'location_lat': lat,
      'location_lng': lng,
    });
  }

  Future<UserProfile?> fetchProfile() async {
    try {
      final uid = _getUid();
      final response = await supabase.from('users').select().eq('id', uid).single();
      return UserProfile.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final uid = _getUid();
    await supabase.from('users').update(data).eq('id', uid);
  }
}
