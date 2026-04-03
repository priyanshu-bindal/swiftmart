import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Singleton getter
  static SupabaseClient get client => Supabase.instance.client;

  // Getter for auth
  static GoTrueClient get auth => client.auth;

  // Getter for current user
  static User? get currentUser => auth.currentUser;

  // Getter for current user ID
  static String? get currentUserId => currentUser?.id;
}
