import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthState {
  final User? firebaseUser;
  final String? customToken;
  final bool isLoading;

  AuthState({this.firebaseUser, this.customToken, this.isLoading = true});

  bool get isAuthenticated => firebaseUser != null || customToken != null;
  User? get user => firebaseUser; // For backward compatibility
}

class AuthNotifier extends Notifier<AuthState> {
  final _storage = const FlutterSecureStorage();

  @override
  AuthState build() {
    _initAuth();
    return AuthState(isLoading: true);
  }

  Future<void> _initAuth() async {
    final token = await _storage.read(key: 'auth_token');
    state = AuthState(
      firebaseUser: FirebaseAuth.instance.currentUser,
      customToken: token,
      isLoading: false,
    );

    final sub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!state.isLoading) {
        state = AuthState(
          firebaseUser: user,
          customToken: state.customToken,
          isLoading: false,
        );
      }
    });
    ref.onDispose(sub.cancel);
  }

  Future<void> setCustomToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
    state = AuthState(
      firebaseUser: state.firebaseUser,
      customToken: token,
      isLoading: false,
    );
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await _storage.delete(key: 'auth_token');
    state = AuthState(isLoading: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
