import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../shared/widgets/avatar_picker_sheet.dart';

class PhotoUploadScreen extends ConsumerStatefulWidget {
  const PhotoUploadScreen({super.key});

  @override
  ConsumerState<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends ConsumerState<PhotoUploadScreen> {
  String? _selectedAvatar;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // If the user already has an avatar (e.g. they're returning to this
    // screen), pre-select it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null && user.photoUrls.isNotEmpty) {
        setState(() => _selectedAvatar = user.photoUrls.first);
      }
    });
  }

  Future<void> _pickAvatar() async {
    final url = await AvatarPickerSheet.show(
      context,
      current: _selectedAvatar,
    );
    if (url != null) setState(() => _selectedAvatar = url);
  }

  Future<void> _continue() async {
    // Persist selection before moving on. If the user skipped picking,
    // proceed without a photo — they can still set one later from the
    // profile screen.
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (_selectedAvatar != null && userId != null) {
      setState(() => _saving = true);
      try {
        await ref.read(firestoreServiceProvider).updateUser(userId, {
          'photoUrls': [_selectedAvatar],
        });
        ref.read(authNotifierProvider.notifier).updateUser(
              (u) => u.copyWith(photoUrls: [_selectedAvatar!]),
            );
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
    if (mounted) context.go('/onboarding/questionnaire');
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('🎨', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    'Pick a profile avatar',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose from our templates — you can swap it out anytime.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.textSoft,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tappable preview circle
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.terracottaSoft,
                            border: Border.all(
                              color: AppColors.terracotta,
                              width: 3,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _selectedAvatar != null
                              ? CachedNetworkImage(
                                  imageUrl: _selectedAvatar!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.terracotta,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    '+',
                                    style: GoogleFonts.inter(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w300,
                                      color: AppColors.terracotta,
                                    ),
                                  ),
                                ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.terracotta,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _selectedAvatar == null
                        ? 'Tap to choose a template'
                        : 'Tap to change',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),

                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.terracottaSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.terracotta,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Custom photo upload is coming soon. For now, pick a template — your match card will show it on the swipe screen.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.terracotta,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _selectedAvatar == null
                                  ? 'Skip for now →'
                                  : 'Continue to lifestyle quiz →',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
