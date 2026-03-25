import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _majorCtrl = TextEditingController();
  final _universityCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null) {
        _nameCtrl.text = user.name;
        _ageCtrl.text = user.age > 16 ? user.age.toString() : '';
        _majorCtrl.text = user.major;
        _universityCtrl.text = user.university;
        _bioCtrl.text = user.bio;
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _ageCtrl.dispose();
    _majorCtrl.dispose(); _universityCtrl.dispose(); _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    // Update local notifier immediately so the UI reflects changes.
    ref.read(authNotifierProvider.notifier).updateUser((user) => user.copyWith(
      name: _nameCtrl.text.trim(),
      age: int.parse(_ageCtrl.text.trim()),
      major: _majorCtrl.text.trim(),
      university: _universityCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
    ));
    // Persist to Firestore (fire-and-forget; questionnaire step sets isProfileComplete).
    if (userId != null) {
      ref.read(firestoreServiceProvider).updateUser(userId, {
        'name': _nameCtrl.text.trim(),
        'age': int.parse(_ageCtrl.text.trim()),
        'major': _majorCtrl.text.trim(),
        'university': _universityCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
      });
    }
    if (mounted) context.go('/onboarding/photos');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 4))],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text('📸', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text("Let's set up your profile",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.navy)),
                    const SizedBox(height: 8),
                    Text('Help potential roommates get to know you',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSoft)),
                    const SizedBox(height: 32),

                    _buildField('University', _universityCtrl, hint: 'Louisiana State University',
                      validator: (v) => v!.trim().isEmpty ? 'University is required' : null),
                    const SizedBox(height: 18),
                    _buildField('Major', _majorCtrl, hint: 'Computer Science',
                      validator: (v) => v!.trim().isEmpty ? 'Major is required' : null),
                    const SizedBox(height: 18),
                    _buildField('Full Name', _nameCtrl, hint: 'Jane Smith',
                      validator: (v) => v!.trim().isEmpty ? 'Name is required' : null),
                    const SizedBox(height: 18),
                    _buildField('Age', _ageCtrl, hint: '19',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final age = int.tryParse(v ?? '');
                        if (age == null || age < 16 || age > 99) return 'Enter a valid age';
                        return null;
                      }),
                    const SizedBox(height: 18),
                    _buildField('Tell us about yourself', _bioCtrl,
                      hint: 'What are your hobbies? What\'s your ideal roommate like?',
                      maxLines: 4,
                      validator: (v) => v!.trim().isEmpty ? 'Bio is required' : null),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Continue to lifestyle quiz →',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {
    String? hint, TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator, int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSoft)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 15, color: AppColors.text),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderLight, width: 2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderLight, width: 2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.terracotta, width: 2)),
          ),
        ),
      ],
    );
  }
}
