import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/avatar_templates.dart';

/// Modal bottom sheet that lets the user pick one of the curated template
/// avatars. Returns the selected URL via [Navigator.pop], or `null` if
/// dismissed.
///
/// Usage:
/// ```dart
/// final url = await AvatarPickerSheet.show(context, current: user.primaryPhoto);
/// if (url != null) { /* persist it */ }
/// ```
class AvatarPickerSheet extends StatelessWidget {
  const AvatarPickerSheet({super.key, this.current});

  /// The user's currently-selected avatar URL, used to highlight the active
  /// option in the grid.
  final String? current;

  /// Convenience launcher.
  static Future<String?> show(BuildContext context, {String? current}) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AvatarPickerSheet(current: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templates = AvatarTemplates.all;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Pick your avatar',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose a template — you can change it anytime.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),

            // Grid of options. Constrain max height so it doesn't blow up
            // on very tall screens.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: templates.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (ctx, i) {
                  final url = templates[i];
                  final isSelected = url == current;
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(url),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.terracotta
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.terracotta
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.surfaceAlt,
                          child: const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.terracotta,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.person,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
