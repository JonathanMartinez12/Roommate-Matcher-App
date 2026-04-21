import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/storage_service.dart';

const int _maxPhotos = 4;

/// A filled photo slot is either a remote URL (already uploaded) or a newly
/// picked local file that still needs to be uploaded on submit.
class _PhotoSlot {
  final String? url;
  final File? file;
  const _PhotoSlot.url(this.url) : file = null;
  const _PhotoSlot.file(this.file) : url = null;
  bool get isLocal => file != null;
}

class PhotoUploadScreen extends ConsumerStatefulWidget {
  const PhotoUploadScreen({super.key});

  @override
  ConsumerState<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends ConsumerState<PhotoUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<_PhotoSlot> _photos = [];
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
  }

  void _loadExisting() {
    final existing =
        ref.read(currentUserProvider).valueOrNull?.photoUrls ?? const [];
    if (existing.isNotEmpty) {
      setState(() {
        _photos.addAll(existing.take(_maxPhotos).map((u) => _PhotoSlot.url(u)));
      });
    }
    setState(() => _loaded = true);
  }

  Future<void> _pickPhoto({required ImageSource source}) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked == null) return;
      setState(() {
        _photos.add(_PhotoSlot.file(File(picked.path)));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  Future<void> _showPickerSheet() async {
    if (_photos.length >= _maxPhotos) return;
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.terracotta),
              title: Text('Choose from gallery',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(source: ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.terracotta),
              title: Text('Take a photo',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(source: ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _removeSlot(int index) async {
    final slot = _photos[index];
    setState(() => _photos.removeAt(index));
    // Delete from storage if it was an already-uploaded URL.
    if (slot.url != null) {
      await ref.read(storageServiceProvider).deletePhoto(slot.url!);
    }
  }

  Future<void> _submit() async {
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (userId == null) return;
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final storage = ref.read(storageServiceProvider);
      final urls = <String>[];
      for (final slot in _photos) {
        if (slot.url != null) {
          urls.add(slot.url!);
        } else if (slot.file != null) {
          urls.add(await storage.uploadProfilePhoto(userId, slot.file!));
        }
      }
      await ref
          .read(firestoreServiceProvider)
          .updateUser(userId, {'photoUrls': urls});
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/onboarding/questionnaire');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.photo_camera_outlined,
                      size: 48, color: AppColors.terracotta),
                  const SizedBox(height: 16),
                  Text('Add your photos',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy)),
                  const SizedBox(height: 8),
                  Text('Profiles with photos get 3× more matches!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 15, color: AppColors.textSoft)),
                  const SizedBox(height: 32),
                  if (!_loaded)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(
                          color: AppColors.terracotta),
                    )
                  else
                    _buildPhotoGrid(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              context.canPop()
                                  ? 'Save photos'
                                  : 'Continue to lifestyle quiz →',
                              style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
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

  Widget _buildPhotoGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tap to add (up to $_maxPhotos)',
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSoft)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(_maxPhotos, (i) {
            final filled = i < _photos.length;
            final isMain = i == 0;
            final size = isMain ? 110.0 : 72.0;
            return _buildSlot(index: i, size: size, isMain: isMain, filled: filled);
          }),
        ),
      ],
    );
  }

  Widget _buildSlot({
    required int index,
    required double size,
    required bool isMain,
    required bool filled,
  }) {
    if (!filled) {
      final isNextSlot = index == _photos.length;
      return GestureDetector(
        onTap: isNextSlot ? _showPickerSheet : null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isMain ? AppColors.terracottaSoft : AppColors.surfaceAlt,
            border: Border.all(
                color: isMain && isNextSlot
                    ? AppColors.terracotta
                    : AppColors.border,
                width: 2),
            borderRadius: BorderRadius.circular(isMain ? 16 : 12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add,
                  size: isMain ? 28 : 24,
                  color: isMain && isNextSlot
                      ? AppColors.terracotta
                      : AppColors.textMuted),
              if (isMain)
                Text('Main',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.terracotta)),
            ],
          ),
        ),
      );
    }

    final slot = _photos[index];
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isMain ? 16 : 12),
            border: Border.all(
                color: isMain ? AppColors.terracotta : AppColors.border,
                width: 2),
          ),
          child: slot.isLocal
              ? Image.file(slot.file!, fit: BoxFit.cover)
              : CachedNetworkImage(imageUrl: slot.url!, fit: BoxFit.cover),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: GestureDetector(
            onTap: () => _removeSlot(index),
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.navy,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
