import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/riverpod.dart';

/// `true`  → navbar is visible (user scrolled up or list is at top)
/// `false` → navbar is hidden  (user scrolled down)
class NavVisibilityNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void show() => state = true;
  void hide() => state = false;
}

final navVisibilityProvider =
    NotifierProvider<NavVisibilityNotifier, bool>(NavVisibilityNotifier.new);
