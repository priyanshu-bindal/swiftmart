import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _violet = Color(0xFF6C3CE1);
const Color _teal = Color(0xFF00D4AA);
const Color _bg = Color(0xFFF9F7FF);
const LinearGradient _btnGrad = LinearGradient(
  colors: [_violet, _teal],
);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _emailError;
  String? _passError;
  String? _firebaseError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool _validateFields() {
    setState(() {
      _emailError = null;
      _passError = null;
      _firebaseError = null;
    });

    bool valid = true;
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email address');
      valid = false;
    }
    if (pass.length < 6) {
      setState(() => _passError = 'Password must be at least 6 characters');
      valid = false;
    }
    return valid;
  }

  Future<void> _login() async {
    if (!_validateFields()) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (mounted) context.go('/');
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

  Future<void> _googleSignIn() async {
    setState(() {
      _loading = true;
      _firebaseError = null;
    });
    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      // In google_sign_in v7, .authentication is synchronous and only provides idToken
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) context.go('/');
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
        _firebaseError = 'Google Sign-In failed. Please try again.';
      });
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Enter your email first');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent!')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _firebaseError = _authError(e.code));
    }
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
      case 'invalid-email':
        return 'Invalid email address';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
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
                width: 120,
                height: 120,
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
                    errorBuilder: (_, __, ___) => const Icon(Icons.storefront, size: 64, color: _violet),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Text(
                'SwiftMart',
                style: GoogleFonts.manrope(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: _violet,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Groceries delivered in minutes',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 36),

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
                    // Email field
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

                    // Password field
                    _label('PASSWORD'),
                    const SizedBox(height: 8),
                    _pillField(
                      controller: _passCtrl,
                      hint: 'Enter your password',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                      error: _passError,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    if (_passError != null) _errorText(_passError!),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.manrope(
                            color: _violet,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    // Firebase error
                    if (_firebaseError != null) ...[
                      Text(
                        _firebaseError!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Continue button
                    _gradientButton(
                      label: 'Continue',
                      loading: _loading,
                      onTap: _loading ? null : _login,
                    ),

                    const SizedBox(height: 20),

                    // OR divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade200)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('OR', style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade200)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Google Sign In
                    GestureDetector(
                      onTap: _loading ? null : _googleSignIn,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.grey.shade200, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                              width: 22,
                              height: 22,
                              errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Continue with Google',
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Sign Up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.manrope(color: Colors.grey.shade600),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/signup'),
                    child: Text(
                      'Sign Up',
                      style: GoogleFonts.manrope(
                        color: _violet,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
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
              : [
                  BoxShadow(
                    color: _violet.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ],
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
            : Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
