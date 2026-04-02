import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AuthState {
  final User? user;
  final bool isLoading;

  AuthState({this.user, this.isLoading = true});

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final auth = FirebaseAuth.instance;

    // Listen to auth state stream
    final sub = auth.authStateChanges().listen((user) {
      state = AuthState(user: user, isLoading: false);
    });
    ref.onDispose(sub.cancel);

    return AuthState(isLoading: true);
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
