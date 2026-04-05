import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';

/// Supabase-only authentication. Firebase is used only for FCM device tokens.
class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile', 'openid'],
  );

  StreamSubscription<String>? _fcmTokenRefreshSub;

  static String get profileTable => SupabaseConstants.profileTable;

  /// Raw Supabase auth stream — use this for routing and session state.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signUpWithEmail(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );
      if (res.session == null) {
        throw AuthException(
          'Account created. Confirm your email if required, then sign in.',
        );
      }
    } on AuthException catch (e) {
      throw AuthException(_mapAuthMessage(e.message));
    } catch (e) {
      throw AuthException(_friendlyError(e));
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthException(_mapAuthMessage(e.message));
    } catch (e) {
      throw AuthException(_friendlyError(e));
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('Google sign-in was cancelled.');
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw AuthException(
          'Could not read Google ID token. Check Google Sign-In / SHA-1 setup.',
        );
      }
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
    } on AuthException catch (e) {
      throw AuthException(_mapAuthMessage(e.message));
    } catch (e) {
      throw AuthException(_friendlyError(e));
    }
  }

  /// Subscribes to topics, loads FCM token, persists to [profileTable], listens for refresh.
  Future<void> saveFcmToken() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await FirebaseMessaging.instance.subscribeToTopic('all_users');
    await FirebaseMessaging.instance.subscribeToTopic('offers');
    await FirebaseMessaging.instance.subscribeToTopic('flash_deals');

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _persistFcmToken(token);
    }

    _fcmTokenRefreshSub?.cancel();
    _fcmTokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((
      newToken,
    ) async {
      final id = _client.auth.currentUser?.id;
      if (id == null) return;
      await _persistFcmToken(newToken);
    });
  }

  Future<void> signOut() async {
    _fcmTokenRefreshSub?.cancel();
    _fcmTokenRefreshSub = null;

    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic('all_users');
      await FirebaseMessaging.instance.unsubscribeFromTopic('offers');
      await FirebaseMessaging.instance.unsubscribeFromTopic('flash_deals');
    } catch (_) {}

    await _googleSignIn.signOut();
    await _client.auth.signOut();
  }

  Future<void> resetPasswordForEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw AuthException(_mapAuthMessage(e.message));
    } catch (e) {
      throw AuthException(_friendlyError(e));
    }
  }

  Future<void> _persistFcmToken(String token) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      await _client
          .from(SupabaseConstants.profileTable)
          .update({
            'fcm_token': token,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', uid);
    } catch (e) {
      debugPrint('AuthService: could not persist FCM token: $e');
    }
  }

  String _mapAuthMessage(String? raw) {
    final m = raw ?? 'Authentication failed.';
    if (m.contains('Invalid login credentials')) {
      return 'Invalid email or password.';
    }
    if (m.contains('User already registered')) {
      return 'An account already exists for this email.';
    }
    if (m.contains('Email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }
    return m;
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('Network')) {
      return 'Network error. Check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
