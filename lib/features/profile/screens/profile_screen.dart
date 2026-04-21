import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';
import '../../../services/matching_service.dart'
    show tagsFromQuestionnaire, kDealbreakerOptions;
import '../../../shared/widgets/custom_app_bar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: RoomrAppBar(
        title: 'Profile',
        showLogo: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.terracotta)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const Center(child: Text('No profile found'));
          return _buildProfile(context, ref, user);
        },
      ),
    );
  }

  Widget _buildProfile(BuildContext context, WidgetRef ref, UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Profile header card
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.terracotta, width: 4),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: user.photoUrls.isNotEmpty
                      ? CachedNetworkImage(imageUrl: user.photoUrls.first, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.terracottaSoft,
                          child: Center(child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.terracotta),
                          )),
                        ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${user.name}, ${user.age}',
                          style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy)),
                      const SizedBox(height: 4),
                      if (user.major.isNotEmpty || user.university.isNotEmpty)
                        Text(
                          [user.major, user.university]
                              .where((s) => s.isNotEmpty)
                              .join(' · '),
                          style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSoft),
                        ),
                      const SizedBox(height: 12),
                      // Tags derived from real questionnaire data
                      if (user.questionnaire != null)
                        Wrap(
                          spacing: 8, runSpacing: 6,
                          children: tagsFromQuestionnaire(user.questionnaire!, maxTags: 4)
                              .map((tag) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(20)),
                                child: Text(tag, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSoft)),
                              )).toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Bio
          if (user.bio.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About me', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
                  const SizedBox(height: 12),
                  Text(user.bio, style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSoft, height: 1.6)),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Dealbreakers card
          if (user.dealbreakers.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My dealbreakers',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.dealbreakers.map((key) {
                      final opt = kDealbreakerOptions
                          .where((o) => o.key == key)
                          .firstOrNull;
                      final label = opt != null
                          ? opt.label
                          : key;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.terracottaSoft,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.terracotta.withValues(alpha: 0.4)),
                        ),
                        child: Text(label,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.terracotta,
                                fontWeight: FontWeight.w500)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Actions
          Column(
            children: [
              _ActionButton(
                label: 'Edit profile',
                onTap: () => context.push('/profile/edit'),
                isDark: false,
              ),
              const SizedBox(height: 12),
              _ActionButton(
                label: 'Update lifestyle preferences',
                onTap: () => context.push('/profile/preferences'),
                isDark: false,
              ),
              const SizedBox(height: 12),
              _ActionButton(
                label: 'Sign out',
                onTap: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go('/login');
                },
                isDark: false,
                isGhost: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isGhost;

  const _ActionButton({required this.label, required this.onTap, this.isDark = false, this.isGhost = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: isGhost ? AppColors.textMuted : AppColors.navy,
          side: BorderSide(color: isGhost ? Colors.transparent : AppColors.border, width: 1.5),
          backgroundColor: isGhost ? Colors.transparent : AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
