import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/supabase_provider.dart';
import 'package:app/core/models/home_config_model.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return HomeRepository(supabase: supabase);
});

class HomeRepository {
  final SupabaseClient supabase;

  HomeRepository({required this.supabase});

  Future<HomeConfigModel?> fetchHomeConfigModel() async {
    try {
      final response = await supabase
          .from('home_config')
          .select()
          .eq('is_active', true)
          .single();

      return HomeConfigModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }
}
