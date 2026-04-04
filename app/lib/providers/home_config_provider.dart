import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/home_config.dart';
import '../../repositories/home_repository.dart';

final homeConfigProvider =
    AsyncNotifierProvider<HomeConfigNotifier, HomeConfig?>(() {
      return HomeConfigNotifier();
    });

class HomeConfigNotifier extends AsyncNotifier<HomeConfig?> {
  @override
  Future<HomeConfig?> build() async {
    final repo = ref.watch(homeRepositoryProvider);
    return await repo.fetchHomeConfig();
  }
}
