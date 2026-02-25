import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/auth_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 12),

          // Account section
          _buildSectionHeader('Account'),
          _buildTile(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () => context.push('/onboarding/profile'),
          ),
          _buildTile(
            icon: Icons.photo_library_outlined,
            title: 'Manage Photos',
            onTap: () => context.push('/onboarding/photos'),
          ),
          _buildTile(
            icon: Icons.quiz_outlined,
            title: 'Update Preferences',
            onTap: () => context.push('/onboarding/questionnaire'),
          ),

          const SizedBox(height: 8),
          _buildSectionHeader('Info'),
          _buildTile(
            icon: Icons.mail_outline,
            title: 'Email',
            subtitle: user?.email ?? '',
            onTap: null,
          ),

          const SizedBox(height: 8),
          _buildSectionHeader('Legal'),
          _buildTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {},
          ),
          _buildTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () {},
          ),

          const SizedBox(height: 8),
          _buildSectionHeader('Session'),
          _buildTile(
            icon: Icons.logout,
            title: 'Sign Out',
            textColor: AppColors.pass,
            iconColor: AppColors.pass,
            onTap: () => _confirmSignOut(context, ref),
          ),
          _buildTile(
            icon: Icons.delete_forever_outlined,
            title: 'Delete Account',
            textColor: AppColors.pass,
            iconColor: AppColors.pass,
            onTap: () => _confirmDelete(context, ref),
          ),

          const SizedBox(height: 32),
          const Center(
            child: Text(
              'Roomr v1.0.0',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textHint,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? textColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(color: AppColors.textHint, fontSize: 13))
            : null,
        trailing: onTap != null
            ? const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20)
            : null,
        onTap: onTap,
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authServiceProvider).signOut();
            },
            child: const Text('Sign Out', style: TextStyle(color: AppColors.pass)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all your data. This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authServiceProvider).deleteAccount();
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.pass)),
          ),
        ],
      ),
    );
  }
}
