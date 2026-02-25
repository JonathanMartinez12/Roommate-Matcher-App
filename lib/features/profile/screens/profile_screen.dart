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
      backgroundColor: AppColors.background,
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
          // Photo area
          _buildPhotoSection(user),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + badges row
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                // Stats badges
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statBadge('${user.age} yrs', AppColors.primary),
                    _statBadge(user.major, AppColors.secondary),
                    _statBadge(user.university, AppColors.accent),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(color: AppColors.border),
                const SizedBox(height: 16),

                // Bio
                if (user.bio.isNotEmpty) ...[
                  _sectionHeader('About me', AppColors.primary),
                  const SizedBox(height: 10),
                  Text(
                    user.bio,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Preferences
                if (user.questionnaire != null) ...[
                  _sectionHeader('Living Preferences', AppColors.secondary),
                  const SizedBox(height: 14),
                  _buildPreferences(user.questionnaire!),
                ],

                const SizedBox(height: 28),

                // Edit profile button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/onboarding/profile'),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text(
                      'Edit Profile',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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

  Widget _sectionHeader(String title, Color accentColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _statBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPhotoSection(UserModel user) {
    if (user.photoUrls.isEmpty) {
      return Container(
        height: 320,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.15),
              AppColors.secondary.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 320,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _prefCategory('Sleep & Noise', AppColors.sleepColor, [
          _prefItem('Sleep', _sleepLabel(q.sleepSchedule), Icons.bedtime_outlined, AppColors.sleepColor),
          _prefItem('Cleanliness', '${q.cleanliness}/5', Icons.cleaning_services_outlined, AppColors.sleepColor),
          _prefItem('Noise', _noiseLevelLabel(q.noiseLevel), Icons.volume_up_outlined, AppColors.sleepColor),
          _prefItem('Morning', _morningLabel(q.morningRoutine), Icons.wb_sunny_outlined, AppColors.sleepColor),
        ]),
        const SizedBox(height: 14),
        _prefCategory('Social Life', AppColors.socialColor, [
          _prefItem('Friday', _fridayLabel(q.fridayNight), Icons.celebration_outlined, AppColors.socialColor),
          _prefItem('Guests', _guestsFreqLabel(q.guestsFrequency), Icons.people_outline, AppColors.socialColor),
          _prefItem('Overnight', _overnightLabel(q.overnightGuests), Icons.hotel_outlined, AppColors.socialColor),
        ]),
        const SizedBox(height: 14),
        _prefCategory('Kitchen & Sharing', AppColors.kitchenColor, [
          _prefItem('Kitchen', _kitchenLabel(q.kitchenHabits), Icons.kitchen_outlined, AppColors.kitchenColor),
          _prefItem('Sharing', _sharingLabel(q.sharingComfort), Icons.handshake_outlined, AppColors.kitchenColor),
          _prefItem('Budget', _rentLabel(q.rentBudget), Icons.attach_money, AppColors.kitchenColor),
        ]),
        const SizedBox(height: 14),
        _prefCategory('Lifestyle', AppColors.lifestyleColor, [
          _prefItem('Smoking', q.smoking ? 'OK' : 'No', Icons.smoking_rooms_outlined, AppColors.lifestyleColor),
          _prefItem('Drinking', q.drinking ? 'OK' : 'No', Icons.local_bar_outlined, AppColors.lifestyleColor),
          _prefItem('Pets', q.pets ? 'OK' : 'No', Icons.pets_outlined, AppColors.lifestyleColor),
          _prefItem('Home freq', _homeFreqLabel(q.homeFrequency), Icons.home_outlined, AppColors.lifestyleColor),
        ]),
      ],
    );
  }

  Widget _prefCategory(String title, Color color, List<Widget> chips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips,
        ),
      ],
    );
  }

  Widget _prefItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _sleepLabel(String s) {
    switch (s) {
      case 'early_bird': return 'Early Bird';
      case 'night_owl': return 'Night Owl';
      default: return 'Flexible';
    }
  }

  String _noiseLevelLabel(String s) {
    switch (s) {
      case 'quiet': return 'Quiet';
      case 'lively': return 'Lively';
      default: return 'Background';
    }
  }

  String _morningLabel(String s) {
    switch (s) {
      case 'quick': return 'Quick';
      case 'long': return 'Long';
      default: return 'Moderate';
    }
  }

  String _fridayLabel(String s) {
    switch (s) {
      case 'studying': return 'Netflix/Study';
      case 'party': return 'Going out';
      default: return 'Low-key';
    }
  }

  String _guestsFreqLabel(String s) {
    switch (s) {
      case 'rarely': return 'Rarely';
      case 'weekends': return 'Weekends';
      case 'always': return 'Always';
      default: return 'Monthly';
    }
  }

  String _overnightLabel(String s) {
    switch (s) {
      case 'prefer_not': return 'Prefer not';
      case 'fine': return 'Fine';
      default: return 'Heads-up';
    }
  }

  String _kitchenLabel(String s) {
    switch (s) {
      case 'cook': return 'Cook often';
      case 'eat_out': return 'Eat out';
      default: return 'Reheat';
    }
  }

  String _sharingLabel(String s) {
    switch (s) {
      case 'separate': return 'Separate';
      case 'share': return 'Shared home';
      default: return 'Some sharing';
    }
  }

  String _rentLabel(String s) {
    switch (s) {
      case 'under_600': return '< \$600';
      case '900_1200': return '\$900–1200';
      case '1200_plus': return '\$1200+';
      default: return '\$600–900';
    }
  }

  String _homeFreqLabel(String s) {
    switch (s) {
      case 'rarely': return 'Rarely';
      case 'often': return 'Often';
      default: return 'Sometimes';
    }
  }
}
