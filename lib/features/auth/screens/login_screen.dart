import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:email_validator/email_validator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/gradient_button.dart';
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.terracotta.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'WELCOME BACK',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ).animate().fadeIn(duration: 360.ms).moveY(begin: -6, end: 0),
                        const SizedBox(height: 24),
                        Text(
                          'Your person is\nout there.',
                          style: AppTheme.displayStyle(
                            fontSize: 56,
                            color: Colors.white,
                            letterSpacing: -2.0,
                            height: 1.05,
                          ),
                        ).animate().fadeIn(duration: 520.ms).moveY(begin: 12, end: 0, curve: Curves.easeOutCubic),
                        const SizedBox(height: 18),
                        Text(
                          'Find a roommate who actually matches your lifestyle — not just your move-in date.',
                          style: GoogleFonts.inter(fontSize: 17, color: Colors.white.withValues(alpha: 0.78), height: 1.6),
                        ).animate(delay: 180.ms).fadeIn(duration: 440.ms),
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
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.terracotta.withValues(alpha: 0.32),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.home_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Text('roomr',
                    style: AppTheme.displayStyle(
                        fontSize: 32, color: AppColors.navy, letterSpacing: -1.0)),
              ],
            ),
            const SizedBox(height: 52),
            Text('Welcome\nback.',
                style: AppTheme.displayStyle(
                    fontSize: 44, color: AppColors.navy, letterSpacing: -1.6, height: 1.05)),
            const SizedBox(height: 12),
            Text('Sign in to keep finding your people.',
                style: GoogleFonts.inter(
                    fontSize: 16, color: AppColors.textSoft, fontWeight: FontWeight.w500)),
            const SizedBox(height: 40),

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
            GradientButton(
              text: 'Sign in',
              isLoading: _isLoading,
              onPressed: _login,
              icon: Icons.arrow_forward_rounded,
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
