import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/matching_service.dart';

class EditPreferencesScreen extends ConsumerStatefulWidget {
  const EditPreferencesScreen({super.key});
  @override
  ConsumerState<EditPreferencesScreen> createState() =>
      _EditPreferencesScreenState();
}

class _EditPreferencesScreenState
    extends ConsumerState<EditPreferencesScreen> {
  // ── Preference state ───────────────────────────────────────────────────────
  String _sleepSchedule = 'flexible';
  int _cleanliness = 3;
  int _noiseTolerance = 3;
  String _studyHabits = 'flexible';
  String _guestPolicy = 'occasionally';
  bool _smoking = false;
  bool _drinking = false;
  bool _pets = false;
  String _temperaturePreference = 'moderate';

  final Set<String> _dealbreakers = {};
  bool _initialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  void _populateFromUser(UserModel user) {
    final q = user.questionnaire;
    if (q != null) {
      _sleepSchedule = q.sleepSchedule;
      _cleanliness = q.cleanliness;
      _noiseTolerance = q.noiseTolerance;
      _studyHabits = q.studyHabits;
      _guestPolicy = q.guestPolicy;
      _smoking = q.smoking;
      _drinking = q.drinking;
      _pets = q.pets;
      _temperaturePreference = q.temperaturePreference;
    }
    _dealbreakers
      ..clear()
      ..addAll(user.dealbreakers);
    _initialized = true;
  }

  void _toggleDealbreaker(String key) {
    setState(() {
      if (_dealbreakers.contains(key)) {
        _dealbreakers.remove(key);
      } else if (_dealbreakers.length < 2) {
        _dealbreakers.add(key);
      }
    });
  }

  Future<void> _save() async {
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
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
        'dealbreakers': _dealbreakers.toList(),
      });

      // Sync local notifier so the profile screen reflects changes instantly.
      ref.read(authNotifierProvider.notifier).updateUser(
            (u) => u.copyWith(
              questionnaire: questionnaire,
              dealbreakers: _dealbreakers.toList(),
            ),
          );

      if (mounted) setState(() => _successMessage = 'Preferences saved!');
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to save. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pre-populate fields once the Firestore stream delivers data.
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (!_initialized && user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_initialized) {
          setState(() => _populateFromUser(user));
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        title: Text('Lifestyle Preferences',
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
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Sleep schedule ───────────────────────────────────────────────
          _sectionHeader('Sleep schedule'),
          _choiceGroup(
            options: const ['Early bird 🌅', 'Night owl 🌙', 'Flexible'],
            values: const ['early_bird', 'night_owl', 'flexible'],
            selected: _sleepSchedule,
            onSelect: (v) => setState(() => _sleepSchedule = v),
          ),
          const SizedBox(height: 24),

          // ── Cleanliness ──────────────────────────────────────────────────
          _sectionHeader('Cleanliness level'),
          _sliderTile(
            label: _cleanlinessLabel(_cleanliness),
            value: _cleanliness.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (v) => setState(() => _cleanliness = v.round()),
          ),
          const SizedBox(height: 24),

          // ── Noise tolerance ──────────────────────────────────────────────
          _sectionHeader('Noise tolerance'),
          _sliderTile(
            label: _noiseLabel(_noiseTolerance),
            value: _noiseTolerance.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (v) => setState(() => _noiseTolerance = v.round()),
          ),
          const SizedBox(height: 24),

          // ── Study habits ─────────────────────────────────────────────────
          _sectionHeader('Favorite study spot'),
          _choiceGroup(
            options: const ['Library', 'Coffee shop', 'Home', 'Flexible'],
            values: const ['library', 'cafe', 'at_home', 'flexible'],
            selected: _studyHabits,
            onSelect: (v) => setState(() => _studyHabits = v),
          ),
          const SizedBox(height: 24),

          // ── Guest policy ─────────────────────────────────────────────────
          _sectionHeader('Guests & socializing'),
          _choiceGroup(
            options: const ['Frequently', 'Occasionally', 'Rarely / Never'],
            values: const ['frequently', 'occasionally', 'never'],
            selected: _guestPolicy,
            onSelect: (v) => setState(() => _guestPolicy = v),
          ),
          const SizedBox(height: 24),

          // ── Temperature ──────────────────────────────────────────────────
          _sectionHeader('Temperature preference'),
          _choiceGroup(
            options: const ['Cool', 'Moderate', 'Warm'],
            values: const ['cool', 'moderate', 'warm'],
            selected: _temperaturePreference,
            onSelect: (v) => setState(() => _temperaturePreference = v),
          ),
          const SizedBox(height: 24),

          // ── Lifestyle toggles ────────────────────────────────────────────
          _sectionHeader('Lifestyle'),
          _toggleCard(
            title: 'Smoking OK',
            subtitle: 'You or your roommate smokes',
            value: _smoking,
            onChanged: (v) => setState(() => _smoking = v),
          ),
          const SizedBox(height: 10),
          _toggleCard(
            title: 'Drinking OK',
            subtitle: 'Alcohol in the shared space',
            value: _drinking,
            onChanged: (v) => setState(() => _drinking = v),
          ),
          const SizedBox(height: 10),
          _toggleCard(
            title: 'Pets OK',
            subtitle: 'Animals in the living space',
            value: _pets,
            onChanged: (v) => setState(() => _pets = v),
          ),

          const SizedBox(height: 28),

          // ── Dealbreakers ──────────────────────────────────────────────────
          _sectionHeader('Dealbreakers (max 2)'),
          Text(
            'You will never see — or be seen by — someone who triggers these.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          ...kDealbreakerOptions.map((opt) {
            final isSelected = _dealbreakers.contains(opt.key);
            final isDisabled = !isSelected && _dealbreakers.length >= 2;
            return GestureDetector(
              onTap: isDisabled ? null : () => _toggleDealbreaker(opt.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.terracottaSoft
                      : isDisabled
                          ? AppColors.surfaceAlt
                          : AppColors.surface,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.terracotta
                        : AppColors.borderLight,
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(opt.icon,
                        size: 22,
                        color: isDisabled
                            ? AppColors.textLight
                            : isSelected
                                ? AppColors.terracotta
                                : AppColors.textSoft),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(opt.label,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isDisabled
                                  ? AppColors.textLight
                                  : isSelected
                                      ? AppColors.terracotta
                                      : AppColors.text)),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle,
                          color: AppColors.terracotta, size: 20),
                  ],
                ),
              ),
            );
          }),
          if (_dealbreakers.length >= 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Maximum 2 dealbreakers selected',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textMuted)),
            ),

          const SizedBox(height: 20),

          if (_errorMessage != null) _banner(_errorMessage!, isError: true),
          if (_successMessage != null)
            _banner(_successMessage!, isError: false),

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
                  : Text('Save Preferences',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Builders ────────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.navy)),
    );
  }

  Widget _choiceGroup({
    required List<String> options,
    required List<String> values,
    required String selected,
    required void Function(String) onSelect,
  }) {
    return Column(
      children: List.generate(options.length, (i) {
        final isSelected = selected == values[i];
        return GestureDetector(
          onTap: () => onSelect(values[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.terracottaSoft
                  : AppColors.surface,
              border: Border.all(
                color: isSelected
                    ? AppColors.terracotta
                    : AppColors.borderLight,
                width: isSelected ? 2.5 : 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(options[i],
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.terracotta
                              : AppColors.text)),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle,
                      color: AppColors.terracotta, size: 20),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _sliderTile({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required void Function(double) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.terracotta)),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: AppColors.terracotta,
            inactiveColor: AppColors.borderLight,
            onChanged: onChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Very low',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textMuted)),
              Text('Very high',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy)),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.terracotta,
          ),
        ],
      ),
    );
  }

  Widget _banner(String message, {required bool isError}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                    color:
                        isError ? AppColors.pass : AppColors.terracotta,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── Label helpers ────────────────────────────────────────────────────────────

  String _cleanlinessLabel(int v) => switch (v) {
        1 => 'Very relaxed (1/5)',
        2 => 'Somewhat relaxed (2/5)',
        3 => 'Moderately clean (3/5)',
        4 => 'Quite clean (4/5)',
        _ => 'Spotless (5/5)',
      };

  String _noiseLabel(int v) => switch (v) {
        1 => 'Very quiet please (1/5)',
        2 => 'Mostly quiet (2/5)',
        3 => 'Moderate noise OK (3/5)',
        4 => 'Pretty tolerant (4/5)',
        _ => 'Very tolerant (5/5)',
      };
}
