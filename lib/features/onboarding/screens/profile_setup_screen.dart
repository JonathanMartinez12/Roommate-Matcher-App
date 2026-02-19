import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../shared/widgets/gradient_button.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill name from auth
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null) {
        _nameCtrl.text = user.name;
        _ageCtrl.text = user.age > 18 ? user.age.toString() : '';
        _majorCtrl.text = user.major;
        _universityCtrl.text = user.university;
        _bioCtrl.text = user.bio;
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _majorCtrl.dispose();
    _universityCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userId = ref.read(authStateProvider).valueOrNull?.uid;
      if (userId == null) return;

      await ref.read(firestoreServiceProvider).updateUser(userId, {
        'name': _nameCtrl.text.trim(),
        'age': int.parse(_ageCtrl.text.trim()),
        'major': _majorCtrl.text.trim(),
        'university': _universityCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
      });

      if (mounted) context.go('/onboarding/photos');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: \${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildField('Full Name', _nameCtrl, hint: 'Jane Smith',
                        validator: (v) => v!.trim().isEmpty ? 'Name is required' : null),
                      const SizedBox(height: 16),
                      _buildField('Age', _ageCtrl, hint: '19',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final age = int.tryParse(v ?? '');
                          if (age == null || age < 16 || age > 99) return 'Enter a valid age';
                          return null;
                        }),
                      const SizedBox(height: 16),
                      _buildField('Major', _majorCtrl, hint: 'Computer Science',
                        validator: (v) => v!.trim().isEmpty ? 'Major is required' : null),
                      const SizedBox(height: 16),
                      _buildField('University', _universityCtrl, hint: 'University of California',
                        validator: (v) => v!.trim().isEmpty ? 'University is required' : null),
                      const SizedBox(height: 16),
                      _buildField('Bio', _bioCtrl,
                        hint: 'Tell potential roommates about yourself...',
                        maxLines: 4,
                        validator: (v) => v!.trim().isEmpty ? 'Bio is required' : null),
                      const SizedBox(height: 32),
                      GradientButton(
                        text: 'Continue',
                        onPressed: _next,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _stepDot(1, active: true)),
              const SizedBox(width: 8),
              Expanded(child: _stepDot(2)),
              const SizedBox(width: 8),
              Expanded(child: _stepDot(3)),
            ],
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tell us about yourself',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Step 1 of 3 — Basic Info',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepDot(int step, {bool active = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: active ? AppColors.primaryGradient : null,
        color: active ? null : AppColors.border,
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
