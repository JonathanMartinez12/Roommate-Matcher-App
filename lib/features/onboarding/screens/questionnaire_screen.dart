import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../shared/widgets/gradient_button.dart';

class QuestionnaireScreen extends ConsumerStatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  ConsumerState<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends ConsumerState<QuestionnaireScreen> {
  String _sleepSchedule = 'flexible';
  int _cleanliness = 3;
  int _noiseTolerance = 3;
  String _studyHabits = 'flexible';
  String _guestPolicy = 'occasionally';
  bool _smoking = false;
  bool _drinking = false;
  bool _pets = false;
  String _temperaturePreference = 'moderate';
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final userId = ref.read(authStateProvider).valueOrNull?.uid;
      if (userId == null) return;

      final questionnaire = Questionnaire(
        sleepSchedule: _sleepSchedule,
        cleanliness: _cleanliness,
        noiseTolerance: _noiseTolerance,
        studyHabits: _studyHabits,
        guestPolicy: _guestPolicy,
        smoking: _smoking,
        drinking: _drinking,
        pets: _pets,
        temperaturePreference: _temperaturePreference,
      );

      await ref.read(firestoreServiceProvider).updateUser(userId, {
        'questionnaire': questionnaire.toMap(),
        'isProfileComplete': true,
      });

      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: ${e.toString()}')),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Sleep Schedule'),
                    _optionRow(
                      options: ['early_bird', 'night_owl', 'flexible'],
                      labels: ['Early Bird', 'Night Owl', 'Flexible'],
                      icons: [Icons.wb_sunny_outlined, Icons.nightlight_outlined, Icons.loop],
                      selected: _sleepSchedule,
                      onSelect: (v) => setState(() => _sleepSchedule = v),
                    ),

                    const SizedBox(height: 24),
                    _sectionTitle('Cleanliness Level'),
                    _sliderRow(
                      value: _cleanliness.toDouble(),
                      min: 1, max: 5,
                      minLabel: 'Messy',
                      maxLabel: 'Spotless',
                      onChanged: (v) => setState(() => _cleanliness = v.round()),
                    ),

                    const SizedBox(height: 24),
                    _sectionTitle('Noise Tolerance'),
                    _sliderRow(
                      value: _noiseTolerance.toDouble(),
                      min: 1, max: 5,
                      minLabel: 'Need Quiet',
                      maxLabel: 'No Problem',
                      onChanged: (v) => setState(() => _noiseTolerance = v.round()),
                    ),

                    const SizedBox(height: 24),
                    _sectionTitle('Study Habits'),
                    _optionRow(
                      options: ['at_home', 'library', 'cafe', 'flexible'],
                      labels: ['At Home', 'Library', 'Cafe', 'Flexible'],
                      icons: [Icons.home_outlined, Icons.menu_book_outlined, Icons.local_cafe_outlined, Icons.loop],
                      selected: _studyHabits,
                      onSelect: (v) => setState(() => _studyHabits = v),
                    ),

                    const SizedBox(height: 24),
                    _sectionTitle('Guest Policy'),
                    _optionRow(
                      options: ['never', 'occasionally', 'frequently'],
                      labels: ['No Guests', 'Occasionally', 'Often'],
                      icons: [Icons.do_not_disturb_outlined, Icons.people_outline, Icons.groups_outlined],
                      selected: _guestPolicy,
                      onSelect: (v) => setState(() => _guestPolicy = v),
                    ),

                    const SizedBox(height: 24),
                    _sectionTitle('Lifestyle'),
                    _toggleRow('Smoking OK', _smoking, (v) => setState(() => _smoking = v)),
                    _toggleRow('Drinking OK', _drinking, (v) => setState(() => _drinking = v)),
                    _toggleRow('Pets OK', _pets, (v) => setState(() => _pets = v)),

                    const SizedBox(height: 24),
                    _sectionTitle('Temperature Preference'),
                    _optionRow(
                      options: ['cool', 'moderate', 'warm'],
                      labels: ['Cool', 'Moderate', 'Warm'],
                      icons: [Icons.ac_unit, Icons.thermostat_outlined, Icons.local_fire_department_outlined],
                      selected: _temperaturePreference,
                      onSelect: (v) => setState(() => _temperaturePreference = v),
                    ),

                    const SizedBox(height: 32),
                    GradientButton(
                      text: 'Find My Roommate!',
                      onPressed: _submit,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 16),
                  ],
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
              Expanded(child: _stepBar(active: true)),
              const SizedBox(width: 8),
              Expanded(child: _stepBar(active: true)),
              const SizedBox(width: 8),
              Expanded(child: _stepBar(active: true)),
            ],
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Your living preferences',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Step 3 of 3 — Help us find your match',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBar({bool active = false}) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: active ? AppColors.primaryGradient : null,
        color: active ? null : AppColors.border,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _optionRow({
    required List<String> options,
    required List<String> labels,
    required List<IconData> icons,
    required String selected,
    required void Function(String) onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(options.length, (i) {
        final isSelected = selected == options[i];
        return GestureDetector(
          onTap: () => onSelect(options[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.primaryGradient : null,
              color: isSelected ? null : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.transparent : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icons[i], size: 16, color: isSelected ? Colors.white : AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _sliderRow({
    required double value,
    required double min,
    required double max,
    required String minLabel,
    required String maxLabel,
    required void Function(double) onChanged,
  }) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primaryBlue,
            thumbColor: AppColors.primaryBlue,
            overlayColor: AppColors.primaryBlue.withValues(alpha: 0.1),
            inactiveTrackColor: AppColors.border,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(minLabel, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            Text(
              value.round().toString(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
            ),
            Text(maxLabel, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
          ],
        ),
      ],
    );
  }

  Widget _toggleRow(String label, bool value, void Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }
}
