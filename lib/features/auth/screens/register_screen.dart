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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passwordCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await ref.read(authServiceProvider).signUp(
        email: _emailCtrl.text, password: _passwordCtrl.text, name: _nameCtrl.text,
      );
    } on Exception catch (e) {
      // ignore: avoid_print
      print('REGISTER ERROR: $e');
      setState(() => _errorMessage = _parseError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseError(String error) {
    if (error.contains('email-already-in-use')) return 'An account already exists with this email.';
    if (error.contains('weak-password')) return 'Password is too weak.';
    if (error.contains('invalid-email')) return 'Invalid email address.';
    return AppStrings.errorGeneric;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    if (isWide) return _buildWideLayout();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: SingleChildScrollView(child: _buildForm())),
    );
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
                      'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=800&h=600&fit=crop',
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
                            'JOIN ROOMR',
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
                          'Find someone\nyou actually\nlike living with.',
                          style: AppTheme.displayStyle(
                            fontSize: 52,
                            color: Colors.white,
                            letterSpacing: -1.8,
                            height: 1.05,
                          ),
                        ).animate().fadeIn(duration: 520.ms).moveY(begin: 12, end: 0, curve: Curves.easeOutCubic),
                        const SizedBox(height: 28),
                        ...['Verified .edu emails only', 'Lifestyle compatibility matching', 'Real students, real connections']
                            .asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 14),
                              Text(e.value, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 16, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ).animate(delay: Duration(milliseconds: 280 + e.key * 100)).fadeIn(duration: 360.ms).moveX(begin: -8, end: 0)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 500, child: _buildForm()),
        ],
      ),
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
            Text('Create your account', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.navy)),
            const SizedBox(height: 8),
            Text('Join the roommate-finding revolution', style: GoogleFonts.inter(fontSize: 16, color: AppColors.textSoft)),
            const SizedBox(height: 36),

            AuthTextField(
              label: 'Full name',
              hint: 'Your name',
              controller: _nameCtrl,
              prefixIcon: const Icon(Icons.person_outline, size: 20, color: AppColors.textMuted),
              validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 4),
            AuthTextField(
              label: 'University email',
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
              hint: 'Create a password',
              controller: _passwordCtrl,
              isPassword: true,
              prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.textMuted),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'At least 6 characters';
                return null;
              },
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.pass.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
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

            GradientButton(
              text: 'Continue',
              isLoading: _isLoading,
              onPressed: _register,
              icon: Icons.arrow_forward_rounded,
            ),

            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account? ', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 15)),
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Text('Sign in', style: GoogleFonts.inter(color: AppColors.terracotta, fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
