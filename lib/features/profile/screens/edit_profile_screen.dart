import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../shared/widgets/avatar_picker_sheet.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _majorCtrl = TextEditingController();
  final _universityCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  bool _initialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _majorCtrl.dispose();
    _universityCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _populateFields() {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null || _initialized) return;
    _nameCtrl.text = user.name;
    _ageCtrl.text = user.age > 0 ? user.age.toString() : '';
    _majorCtrl.text = user.major;
    _universityCtrl.text = user.university;
    _bioCtrl.text = user.bio;
    _initialized = true;
  }

  Future<void> _changeAvatar() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (userId == null) return;
    final current = (user?.photoUrls.isNotEmpty ?? false)
        ? user!.photoUrls.first
        : null;

    final picked = await AvatarPickerSheet.show(context, current: current);
    if (picked == null) return;

    // Persist immediately and reflect in the local notifier so the avatar
    // updates everywhere in the app without needing the Save button.
    try {
      await ref.read(firestoreServiceProvider).updateUser(userId, {
        'photoUrls': [picked],
      });
      ref.read(authNotifierProvider.notifier).updateUser(
            (u) => u.copyWith(photoUrls: [picked]),
          );
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Couldn\'t update your avatar.');
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await ref.read(firestoreServiceProvider).updateUser(userId, {
        'name': _nameCtrl.text.trim(),
        'age': int.parse(_ageCtrl.text.trim()),
        'major': _majorCtrl.text.trim(),
        'university': _universityCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
      });
      // Also update the local notifier so UI reflects change instantly.
      ref.read(authNotifierProvider.notifier).updateUser((u) => u.copyWith(
            name: _nameCtrl.text.trim(),
            age: int.parse(_ageCtrl.text.trim()),
            major: _majorCtrl.text.trim(),
            university: _universityCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
          ));
      if (mounted) setState(() => _successMessage = 'Profile saved!');
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Failed to save. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Populate once the stream delivers data.
    ref.listen(currentUserProvider, (_, next) {
      if (!_initialized) _populateFields();
    });
    _populateFields();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        title: Text('Edit Profile',
            style: GoogleFonts.inter(
                fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: Text('Save',
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildAvatarHeader(),
            const SizedBox(height: 24),
            _buildField('Full Name', _nameCtrl,
                hint: 'Jane Smith',
                validator: (v) =>
                    v!.trim().isEmpty ? 'Name is required' : null),
            const SizedBox(height: 16),
            _buildField('Age', _ageCtrl,
                hint: '19',
                keyboardType: TextInputType.number,
                validator: (v) {
                  final age = int.tryParse(v ?? '');
                  if (age == null || age < 16 || age > 99) {
                    return 'Enter a valid age (16–99)';
                  }
                  return null;
                }),
            const SizedBox(height: 16),
            _buildField('Major', _majorCtrl,
                hint: 'Computer Science',
                validator: (v) =>
                    v!.trim().isEmpty ? 'Major is required' : null),
            const SizedBox(height: 16),
            _buildField('University', _universityCtrl,
                hint: 'Louisiana State University',
                validator: (v) =>
                    v!.trim().isEmpty ? 'University is required' : null),
            const SizedBox(height: 16),
            _buildField('Bio', _bioCtrl,
                hint: 'Tell potential roommates about yourself...',
                maxLines: 5,
                validator: (v) =>
                    v!.trim().isEmpty ? 'Bio is required' : null),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              _banner(_errorMessage!, isError: true),
            if (_successMessage != null)
              _banner(_successMessage!, isError: false),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Save Changes',
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarHeader() {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final url = (user?.photoUrls.isNotEmpty ?? false)
        ? user!.photoUrls.first
        : null;

    return Center(
      child: GestureDetector(
        onTap: _changeAvatar,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.terracottaSoft,
                border: Border.all(color: AppColors.terracotta, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: url != null
                  ? CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.terracotta,
                          strokeWidth: 2,
                        ),
                      ),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.person,
                        size: 48,
                        color: AppColors.terracotta,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 48,
                      color: AppColors.terracotta,
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.terracotta,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 14),
            ),
          ],
        ),
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
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSoft)),
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.borderLight, width: 2)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.borderLight, width: 2)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.terracotta, width: 2)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.pass, width: 2)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.pass, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _banner(String message, {required bool isError}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isError ? AppColors.pass : AppColors.terracotta)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? AppColors.pass : AppColors.terracotta,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    color: isError ? AppColors.pass : AppColors.terracotta,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
