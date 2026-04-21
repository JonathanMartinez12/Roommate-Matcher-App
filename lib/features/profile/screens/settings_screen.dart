import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        title: Text('Settings', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _section('Account', [
            _tile(context, icon: Icons.person_outline, title: 'Edit Profile', onTap: () => context.push('/profile/edit')),
            _tile(context, icon: Icons.photo_library_outlined, title: 'Manage Photos', onTap: () => context.push('/onboarding/photos')),
            _tile(context, icon: Icons.tune_outlined, title: 'Lifestyle Preferences', onTap: () => context.push('/profile/preferences')),
          ]),
          const SizedBox(height: 16),
          _section('Notifications', [
            _switchTile(
              icon: Icons.favorite_outline,
              title: 'New matches',
              value: user?.notifyOnMatch ?? true,
              onChanged: (v) => ref
                  .read(firestoreServiceProvider)
                  .updateNotificationPreferences(notifyOnMatch: v),
            ),
            _switchTile(
              icon: Icons.chat_bubble_outline,
              title: 'New messages',
              value: user?.notifyOnMessage ?? true,
              onChanged: (v) => ref
                  .read(firestoreServiceProvider)
                  .updateNotificationPreferences(notifyOnMessage: v),
            ),
          ]),
          const SizedBox(height: 16),
          _section('Info', [
            _tile(context, icon: Icons.mail_outline, title: 'Email', subtitle: user?.email ?? '', onTap: null),
          ]),
          const SizedBox(height: 16),
          _section('Legal', [
            _tile(context, icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', onTap: () {}),
            _tile(context, icon: Icons.description_outlined, title: 'Terms of Service', onTap: () {}),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go('/login');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.pass,
                side: const BorderSide(color: AppColors.pass),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Sign out', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> tiles) {
    return Builder(builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.8)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(children: tiles),
        ),
      ],
    ));
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.terracotta),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title,
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.navy)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.terracotta,
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, {required IconData icon, required String title, String? subtitle, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.terracotta),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.navy)),
                  if (subtitle != null)
                    Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: AppColors.textLight, size: 20),
          ],
        ),
      ),
    );
  }
}
