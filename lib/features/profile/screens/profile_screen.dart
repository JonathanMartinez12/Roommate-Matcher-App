import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: RoomrAppBar(
        title: 'Profile',
        useGradientTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const Center(child: Text('No profile found'));
          return _buildProfile(context, user);
        },
      ),
    );
  }

  Widget _buildProfile(BuildContext context, UserModel user) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Photo gallery
          _buildPhotoSection(user),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + age
                Row(
                  children: [
                    Text(
                      '${user.name}, ${user.age}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.school_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${user.major} • ${user.university}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(color: AppColors.border),
                const SizedBox(height: 16),

                // Bio
                if (user.bio.isNotEmpty) ...[
                  const Text(
                    'About me',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.bio,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Preferences
                if (user.questionnaire != null) ...[
                  const Text(
                    'Living Preferences',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPreferences(user.questionnaire!),
                ],

                const SizedBox(height: 28),
                // Edit profile button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => context.push('/onboarding/profile'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(UserModel user) {
    if (user.photoUrls.isEmpty) {
      return Container(
        height: 300,
        color: AppColors.primaryBlue.withOpacity(0.1),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: user.photoUrls.length,
        itemBuilder: (_, i) => CachedNetworkImage(
          imageUrl: user.photoUrls[i],
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildPreferences(Questionnaire q) {
    final prefs = [
      ('Sleep', _sleepLabel(q.sleepSchedule), Icons.bedtime_outlined),
      ('Cleanliness', '${q.cleanliness}/5', Icons.cleaning_services_outlined),
      ('Noise', '${q.noiseTolerance}/5', Icons.volume_up_outlined),
      ('Study', _studyLabel(q.studyHabits), Icons.menu_book_outlined),
      ('Guests', _guestLabel(q.guestPolicy), Icons.people_outline),
      ('Smoking', q.smoking ? 'Yes' : 'No', Icons.smoking_rooms_outlined),
      ('Drinking', q.drinking ? 'Yes' : 'No', Icons.local_bar_outlined),
      ('Pets', q.pets ? 'Yes' : 'No', Icons.pets_outlined),
      ('Temp', _tempLabel(q.temperaturePreference), Icons.thermostat_outlined),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: prefs.map((p) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(p.$3, size: 16, color: AppColors.primaryBlue),
              const SizedBox(width: 6),
              Text(
                '${p.$1}: ${p.$2}',
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _sleepLabel(String s) {
    switch (s) {
      case 'early_bird': return 'Early Bird';
      case 'night_owl': return 'Night Owl';
      default: return 'Flexible';
    }
  }

  String _studyLabel(String s) {
    switch (s) {
      case 'at_home': return 'At Home';
      case 'library': return 'Library';
      case 'cafe': return 'Cafe';
      default: return 'Flexible';
    }
  }

  String _guestLabel(String s) {
    switch (s) {
      case 'never': return 'Never';
      case 'frequently': return 'Often';
      default: return 'Sometimes';
    }
  }

  String _tempLabel(String s) {
    switch (s) {
      case 'cool': return 'Cool';
      case 'warm': return 'Warm';
      default: return 'Moderate';
    }
  }
}
