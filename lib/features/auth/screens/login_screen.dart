import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:email_validator/email_validator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await ref.read(authServiceProvider).signIn(email: _emailCtrl.text, password: _passwordCtrl.text);
    } on Exception catch (e) {
      setState(() => _errorMessage = _parseError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseError(String error) {
    if (error.contains('user-not-found')) return 'No account found with this email.';
    if (error.contains('wrong-password')) return 'Incorrect password.';
    if (error.contains('invalid-credential')) return 'Invalid email or password.';
    if (error.contains('too-many-requests')) return 'Too many attempts. Please try again later.';
    return AppStrings.errorGeneric;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 768;

    if (isWide) return _buildWideLayout();
    return _buildNarrowLayout();
  }

  Widget _buildWideLayout() {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          // Left panel
          Expanded(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.navyGradient),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=800&h=600&fit=crop',
                      fit: BoxFit.cover,
                      color: Colors.black.withValues(alpha: 0.7),
                      colorBlendMode: BlendMode.darken,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(60),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your perfect roommate is waiting',
                          style: GoogleFonts.inter(fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Join thousands of students finding compatible roommates based on lifestyle, habits, and personality.',
                          style: GoogleFonts.inter(fontSize: 18, color: Colors.white.withValues(alpha: 0.8), height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right panel
          SizedBox(width: 500, child: _buildForm()),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: SingleChildScrollView(child: _buildForm())),
    );
  }

  Widget _buildForm() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(60),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: AppColors.terracotta, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.home_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Text('roomr', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.navy)),
              ],
            ),
            const SizedBox(height: 48),
            Text('Welcome back', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.navy)),
            const SizedBox(height: 8),
            Text('Sign in to continue your roommate search', style: GoogleFonts.inter(fontSize: 16, color: AppColors.textSoft)),
            const SizedBox(height: 36),

            AuthTextField(
              label: 'Email',
              hint: 'you@university.edu',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.mail_outline, size: 20, color: AppColors.textMuted),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!EmailValidator.validate(v)) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 4),
            AuthTextField(
              label: 'Password',
              hint: 'Password',
              controller: _passwordCtrl,
              isPassword: true,
              prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.textMuted),
              textInputAction: TextInputAction.done,
              onEditingComplete: _login,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                return null;
              },
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.pass.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.pass, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.pass, fontSize: 13))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Sign in button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Sign in', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),

            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account? ", style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 15)),
                GestureDetector(
                  onTap: () => context.go('/register'),
                  child: Text('Sign up free', style: GoogleFonts.inter(color: AppColors.terracotta, fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
