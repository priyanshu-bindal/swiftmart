import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/models/user_model.dart';
import '../services/auth_service.dart';
import '../../../core/providers/fcm_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(Supabase.instance.client);
});

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// App-level auth UI state (distinct from Gotrue’s [AuthState]).
class AppAuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AppAuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AppAuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AppAuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool get isLoading => status == AuthStatus.loading;
  bool get isLoggedIn => status == AuthStatus.authenticated;
  bool get isAuthenticated => isLoggedIn;
}

class AuthNotifier extends Notifier<AppAuthState> {
  AuthService get _auth => ref.read(authServiceProvider);
  StreamSubscription<AuthState>? _supabaseAuthSub;

  @override
  AppAuthState build() {
    _supabaseAuthSub = _auth.authStateChanges.listen(_onSupabaseAuth);

    ref.onDispose(() {
      _supabaseAuthSub?.cancel();
    });

    return const AppAuthState(status: AuthStatus.loading);
  }

  Future<void> _onSupabaseAuth(AuthState authState) async {
    final session = authState.session;
    if (session == null) {
      state = const AppAuthState(status: AuthStatus.unauthenticated);
      return;
    }

    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    await _loadProfileAndFcm(session.user.id);
  }

  Future<void> _loadProfileAndFcm(String userId) async {
    try {
      await ref.read(authServiceProvider).saveFcmToken();

      final row = await Supabase.instance.client
          .from(SupabaseConstants.profileTable)
          .select()
          .eq('id', userId)
          .maybeSingle();

      final user = row != null
          ? UserModel.fromJson(row)
          : UserModel(id: userId, email: Supabase.instance.client.auth.currentUser?.email);

      state = AppAuthState(status: AuthStatus.authenticated, user: user);

      final fcm = ref.read(fcmProvider);
      await fcm.requestPermission();
      fcm.handleForegroundMessages();
      fcm.handleBackgroundMessages();
    } catch (e, st) {
      debugPrint('Auth profile load failed: $e\n$st');
      state = AppAuthState(
        status: AuthStatus.error,
        errorMessage: 'Could not load your profile. Try again.',
      );
    }
  }

  Future<void> signUpWithEmail(
    String email,
    String password,
    String fullName,
  ) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      await _auth.signUpWithEmail(email, password, fullName);
    } on AuthException catch (e) {
      state = AppAuthState(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = AppAuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      await _auth.signInWithEmail(email, password);
    } on AuthException catch (e) {
      state = AppAuthState(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = AppAuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      await _auth.signInWithGoogle();
    } on AuthException catch (e) {
      state = AppAuthState(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = AppAuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      await _auth.signOut();
    } on AuthException catch (e) {
      state = AppAuthState(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = AppAuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> resetPasswordForEmail(String email) async {
    try {
      await _auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      state = AppAuthState(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      rethrow;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AppAuthState>(() {
  return AuthNotifier();
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoggedIn;
});
