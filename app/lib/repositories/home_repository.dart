import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/supabase_provider.dart';
import '../models/home_config.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return HomeRepository(supabase: supabase);
});

class HomeRepository {
  final SupabaseClient supabase;

  HomeRepository({required this.supabase});

  Future<HomeConfig?> fetchHomeConfig() async {
    try {
      final response = await supabase
          .from('home_config')
          .select()
          .eq('is_active', true)
          .single();

      return HomeConfig.fromJson(response);
    } catch (_) {
      return null;
    }
  }
}
