import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/models/user_model.dart';
import '../../../../core/services/supabase_service.dart';

class AuthRepository {
  final supabase.SupabaseClient _client = SupabaseService.client;
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Helper to bridge Firebase token to Supabase
  Future<void> _bridgeToSupabase(firebase_auth.User firebaseUser) async {
    final token = await firebaseUser.getIdToken();
    if (token != null) {
      // Bridging to Supabase using signInWithIdToken. Passing Google provider 
      // as Supabase allows it for generic ID tokens if configured correctly.
      await _client.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: token,
      );
    }
  }

  // EMAIL + PASSWORD
  
  Future<UserModel> signUpWithEmail(String email, String password, String name) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    if (userCredential.user == null) {
      throw Exception('Email already registered or sign up failed');
    }

    await userCredential.user!.updateDisplayName(name);
    
    await _bridgeToSupabase(userCredential.user!);
    
    // The trigger auto-creates the users row
    // Fetch newly created user row
    final userId = _client.auth.currentSession?.user.id ?? '';
    final data = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data != null) {
      return UserModel.fromJson(data);
    }
    
    return UserModel(
      id: userId.isEmpty ? userCredential.user!.uid : userId,
      email: email,
      name: name,
    );
  }

  Future<UserModel> signInWithEmail(String email, String password) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential.user == null) {
      throw Exception('Invalid email or password');
    }

    await _bridgeToSupabase(userCredential.user!);

    final userId = _client.auth.currentSession?.user.id ?? '';
    final data = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
        
    if (data != null) {
      return UserModel.fromJson(data);
    }

    return UserModel(
      id: userId.isEmpty ? userCredential.user!.uid : userId,
      email: email,
      name: userCredential.user!.displayName ?? '',
    );
  }

  // GOOGLE SIGN IN
  
  Future<UserModel?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return null; // User canceled
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final firebase_auth.OAuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    
    if (userCredential.user == null) {
      throw Exception('Could not authenticate with Google');
    }

    await _bridgeToSupabase(userCredential.user!);

    return await getCurrentUser();
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
    await _client.auth.signOut();
  }

  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return null;
    }
    
    try {
      final userId = _client.auth.currentSession?.user.id ?? '';
      if (userId.isEmpty) return null;
      
      final data = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return UserModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateProfile({String? name, String? fcmToken}) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return;
    
    // Update Firebase display name if needed
    if (name != null && name != firebaseUser.displayName) {
      await firebaseUser.updateDisplayName(name);
    }
    
    Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (fcmToken != null) updates['fcm_token'] = fcmToken;
    if (updates.isEmpty) return;

    updates['updated_at'] = DateTime.now().toIso8601String();
    
    final userId = _client.auth.currentSession?.user.id ?? '';
    if (userId.isEmpty) return;
    
    await _client
        .from('users')
        .update(updates)
        .eq('id', userId);
  }

  Stream<firebase_auth.User?> get authStateStream => _firebaseAuth.authStateChanges();
}
