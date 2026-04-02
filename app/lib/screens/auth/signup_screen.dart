import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../providers/location_provider.dart';

const Color _violet = Color(0xFF6C3CE1);
const Color _teal = Color(0xFF00D4AA);
const Color _bg = Color(0xFFF9F7FF);
const LinearGradient _btnGrad = LinearGradient(colors: [_violet, _teal]);

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  String? _nameError;
  String? _emailError;
  String? _passError;
  String? _confirmPassError;
  String? _firebaseError;

  final _storage = const FlutterSecureStorage();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  bool _validateFields() {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passError = null;
      _confirmPassError = null;
      _firebaseError = null;
    });

    bool valid = true;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _nameError = 'Please enter your full name');
      valid = false;
    }
    if (!emailRegex.hasMatch(_emailCtrl.text.trim())) {
      setState(() => _emailError = 'Please enter a valid email address');
      valid = false;
    }
    if (_passCtrl.text.length < 6) {
      setState(() => _passError = 'Password must be at least 6 characters');
      valid = false;
    }
    if (_confirmPassCtrl.text != _passCtrl.text) {
      setState(() => _confirmPassError = 'Passwords do not match');
      valid = false;
    }
    return valid;
  }

  Future<void> _createAccount() async {
    if (!_validateFields()) return;
    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      // Update display name
      await FirebaseAuth.instance.currentUser
          ?.updateDisplayName(_nameCtrl.text.trim());

      if (!mounted) return;

      // Show location bottom sheet
      await _showLocationSheet();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _firebaseError = _authError(e.code);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _firebaseError = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _showLocationSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _LocationBottomSheet(
        onUseLocation: () async {
          Navigator.pop(context);
          await _requestAndSaveLocation();
        },
        onSkip: () async {
          Navigator.pop(context);
          await _saveAndNavigate(location: 'Set location');
        },
      ),
    );
  }

  Future<void> _requestAndSaveLocation() async {
    // Delegate to the shared location provider (has full error handling)
    final error = await ref.read(locationProvider.notifier).requestAndUpdate();
    if (!mounted) return;

    final resolvedLocation = ref.read(locationProvider);
    if (error != null) {
      // Show error but still save name and navigate with 'Set location'
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red.shade700),
      );
    }
    await _saveAndNavigate(location: resolvedLocation);
  }

  Future<void> _saveAndNavigate({required String location}) async {
    await _storage.write(key: 'user_name', value: _nameCtrl.text.trim());
    await _storage.write(key: 'user_location', value: location);

    if (!mounted) return;
    context.go('/');
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'network-request-failed':
        return 'No internet connection';
      case 'weak-password':
        return 'Password is too weak';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _violet.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    'https://cdn-icons-png.flaticon.com/512/4645/4645948.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.storefront, size: 56, color: _violet),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'Create Account',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _violet,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign up to get started',
                style: GoogleFonts.manrope(fontSize: 15, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 28),

              // Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _violet.withValues(alpha: 0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('FULL NAME'),
                    const SizedBox(height: 8),
                    _pillField(
                      controller: _nameCtrl,
                      hint: 'Enter your full name',
                      icon: Icons.person_outline_rounded,
                      error: _nameError,
                    ),
                    if (_nameError != null) _errorText(_nameError!),
                    const SizedBox(height: 20),

                    _label('EMAIL ADDRESS'),
                    const SizedBox(height: 8),
                    _pillField(
                      controller: _emailCtrl,
                      hint: 'Enter your email',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      error: _emailError,
                    ),
                    if (_emailError != null) _errorText(_emailError!),
                    const SizedBox(height: 20),

                    _label('PASSWORD'),
                    const SizedBox(height: 8),
                    _pillField(
                      controller: _passCtrl,
                      hint: 'Create a password',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscurePass,
                      error: _passError,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                    if (_passError != null) _errorText(_passError!),
                    const SizedBox(height: 20),

                    _label('CONFIRM PASSWORD'),
                    const SizedBox(height: 8),
                    _pillField(
                      controller: _confirmPassCtrl,
                      hint: 'Repeat your password',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscureConfirm,
                      error: _confirmPassError,
                      suffix: IconButton(
                        icon: Icon(
                          _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    if (_confirmPassError != null) _errorText(_confirmPassError!),
                    const SizedBox(height: 24),

                    if (_firebaseError != null) ...[
                      Text(_firebaseError!,
                          style: const TextStyle(color: Colors.red, fontSize: 13)),
                      const SizedBox(height: 8),
                    ],

                    _gradientButton(
                      label: 'Create Account',
                      loading: _loading,
                      onTap: _loading ? null : _createAccount,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? ",
                      style: GoogleFonts.manrope(color: Colors.grey.shade600)),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text('Log In',
                        style: GoogleFonts.manrope(color: _violet, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.manrope(
            fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 1.2),
      );

  Widget _errorText(String text) => Padding(
        padding: const EdgeInsets.only(top: 4, left: 4),
        child: Text(text, style: const TextStyle(color: Colors.red, fontSize: 12)),
      );

  Widget _pillField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    String? error,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(50),
        border: error != null ? Border.all(color: Colors.red.shade300) : null,
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: GoogleFonts.manrope(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _gradientButton({
    required String label,
    required bool loading,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: loading ? null : _btnGrad,
          color: loading ? Colors.grey.shade300 : null,
          borderRadius: BorderRadius.circular(50),
          boxShadow: loading
              ? []
              : [BoxShadow(color: _violet.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(label,
                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }
}

// ─── Location Bottom Sheet ────────────────────────────────────────────────────

class _LocationBottomSheet extends StatelessWidget {
  final VoidCallback onUseLocation;
  final VoidCallback onSkip;

  const _LocationBottomSheet({
    required this.onUseLocation,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_violet, _teal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _violet.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 36),
          ),

          const SizedBox(height: 20),

          Text(
            'Where should we deliver?',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1A1B21),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'SwiftMart needs your location to show nearby stores and deliver in under 30 minutes.',
            style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 28),

          // Use My Location
          GestureDetector(
            onTap: onUseLocation,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_violet, _teal]),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: _violet.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              alignment: Alignment.center,
              child: Text('Use My Location',
                  style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),

          const SizedBox(height: 12),

          // Skip for now
          GestureDetector(
            onTap: onSkip,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: _violet.withValues(alpha: 0.4), width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text('Skip for now',
                  style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: _violet)),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
