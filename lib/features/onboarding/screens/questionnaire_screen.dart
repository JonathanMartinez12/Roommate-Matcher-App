import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/matching_service.dart';
import '../../../services/notification_service.dart';

class QuestionnaireScreen extends ConsumerStatefulWidget {
  const QuestionnaireScreen({super.key});
  @override
  ConsumerState<QuestionnaireScreen> createState() =>
      _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends ConsumerState<QuestionnaireScreen> {
  int _step = 1;
  static const int _totalSteps = 7;

  // ── Questionnaire answers ──────────────────────────────────────────────────
  String _sleepSchedule = 'flexible';
  int _cleanliness = 3;
  int _noiseTolerance = 3;
  String _studyHabits = 'flexible';
  String _guestPolicy = 'occasionally';
  bool _smoking = false;
  bool _drinking = false;
  bool _pets = false;
  String _temperaturePreference = 'moderate';

  // ── Dealbreakers (max 2) ───────────────────────────────────────────────────
  final Set<String> _dealbreakers = {};

  bool _isLoading = false;

  void _toggleDealbreaker(String key) {
    setState(() {
      if (_dealbreakers.contains(key)) {
        _dealbreakers.remove(key);
      } else if (_dealbreakers.length < 2) {
        _dealbreakers.add(key);
      }
    });
  }

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
        'dealbreakers': _dealbreakers.toList(),
        'isProfileComplete': true,
      });
      // Request push notification permission at the end of onboarding.
      // NotificationService.init() persists the FCM token and is idempotent.
      await ref.read(notificationServiceProvider).init();
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
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 560),
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
                  _buildProgress(),
                  _buildStepContent(),
                  const SizedBox(height: 32),
                  _buildNavButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgress() {
    final pct = _step / _totalSteps;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Step $_step of $_totalSteps',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textMuted)),
            Text('${(pct * 100).round()}%',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.terracotta)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 10,
            backgroundColor: AppColors.creamDark,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.terracotta),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      // ── Step 1: Sleep schedule ───────────────────────────────────────────
      case 1:
        return _buildChoice(
          question: "What's your sleep schedule like?",
          options: const [
            'Early bird — Up with the sun',
            'Night owl — Alive after midnight',
            'It depends on the day',
          ],
          values: const ['early_bird', 'night_owl', 'flexible'],
          selected: _sleepSchedule,
          onSelect: (v) => setState(() => _sleepSchedule = v),
        );

      // ── Step 2: Cleanliness ──────────────────────────────────────────────
      case 2:
        return _buildChoice(
          question: 'How tidy do you keep your space?',
          options: const [
            'Spotless — I clean daily',
            'Reasonably clean',
            'Organised chaos works for me',
          ],
          values: const ['5', '3', '1'],
          selected: _cleanliness == 5
              ? '5'
              : _cleanliness <= 2
                  ? '1'
                  : '3',
          onSelect: (v) => setState(() => _cleanliness = int.parse(v)),
        );

      // ── Step 3: Noise tolerance ──────────────────────────────────────────
      case 3:
        return _buildChoice(
          question: 'How do you feel about noise at home?',
          options: const [
            'Dead quiet — I need to focus',
            'Some background noise is fine',
            'The louder the better',
          ],
          values: const ['1', '3', '5'],
          selected: _noiseTolerance <= 1
              ? '1'
              : _noiseTolerance >= 5
                  ? '5'
                  : '3',
          onSelect: (v) => setState(() => _noiseTolerance = int.parse(v)),
        );

      // ── Step 4: Study habits ─────────────────────────────────────────────
      case 4:
        return _buildChoice(
          question: "Where's your favourite study spot?",
          options: const [
            'Library — Need that quiet focus',
            'Coffee shops — Vibes matter',
            'Home — Comfort is key',
            "Flexible — wherever I end up",
          ],
          values: const ['library', 'cafe', 'at_home', 'flexible'],
          selected: _studyHabits,
          onSelect: (v) => setState(() => _studyHabits = v),
        );

      // ── Step 5: Guests ───────────────────────────────────────────────────
      case 5:
        return _buildChoice(
          question: 'How social are you at home?',
          options: const [
            'Love having friends over!',
            'Sometimes on weekends',
            'I prefer quiet nights in',
          ],
          values: const ['frequently', 'occasionally', 'never'],
          selected: _guestPolicy,
          onSelect: (v) => setState(() => _guestPolicy = v),
        );

      // ── Step 6: Lifestyle toggles ────────────────────────────────────────
      case 6:
        return _buildLifestyle();

      // ── Step 7: Dealbreakers ─────────────────────────────────────────────
      case 7:
        return _buildDealbreakers();

      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step builders ──────────────────────────────────────────────────────────

  Widget _buildChoice({
    required String question,
    required List<String> options,
    required List<String> values,
    required String selected,
    required void Function(String) onSelect,
  }) {
    return Column(
      children: [
        Text(question,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.navy)),
        const SizedBox(height: 24),
        ...List.generate(options.length, (i) {
          final isSelected = selected == values[i];
          return GestureDetector(
            onTap: () => onSelect(values[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.terracottaSoft : AppColors.surface,
                border: Border.all(
                  color: isSelected
                      ? AppColors.terracotta
                      : AppColors.borderLight,
                  width: isSelected ? 3 : 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(options[i],
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.terracotta
                                  : AppColors.text)),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle,
                          color: AppColors.terracotta, size: 22),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLifestyle() {
    return Column(
      children: [
        Text('Tell us about your lifestyle',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.navy)),
        const SizedBox(height: 8),
        Text('Be honest — this helps find your best match',
            textAlign: TextAlign.center,
            style:
                GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted)),
        const SizedBox(height: 28),
        _lifestyleToggle(
          emoji: '🚬',
          title: 'I smoke',
          subtitle: 'Cigarettes, vaping, etc.',
          value: _smoking,
          onChanged: (v) => setState(() => _smoking = v),
        ),
        const SizedBox(height: 12),
        _lifestyleToggle(
          emoji: '🍺',
          title: 'I drink alcohol',
          subtitle: 'Casually or regularly',
          value: _drinking,
          onChanged: (v) => setState(() => _drinking = v),
        ),
        const SizedBox(height: 12),
        _lifestyleToggle(
          emoji: '🐾',
          title: 'I have pets',
          subtitle: 'Or plan to in the future',
          value: _pets,
          onChanged: (v) => setState(() => _pets = v),
        ),
        const SizedBox(height: 20),
        // Temperature preference
        Text('Temperature preference',
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.navy)),
        const SizedBox(height: 14),
        _buildChoice(
          question: '',
          options: const ['Cool', 'Moderate', 'Warm'],
          values: const ['cool', 'moderate', 'warm'],
          selected: _temperaturePreference,
          onSelect: (v) => setState(() => _temperaturePreference = v),
        ),
      ],
    );
  }

  Widget _lifestyleToggle({
    required String emoji,
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: value ? AppColors.terracottaSoft : AppColors.surface,
          border: Border.all(
            color: value ? AppColors.terracotta : AppColors.borderLight,
            width: value ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy)),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textMuted)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.terracotta,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealbreakers() {
    return Column(
      children: [
        Text('Set your dealbreakers',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.navy)),
        const SizedBox(height: 8),
        Text(
          'Pick up to 2. You will never be shown someone who triggers these.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        ...kDealbreakerOptions.map((opt) {
          final isSelected = _dealbreakers.contains(opt.key);
          final isDisabled = !isSelected && _dealbreakers.length >= 2;
          return GestureDetector(
            onTap: isDisabled ? null : () => _toggleDealbreaker(opt.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(opt.icon, size: 24, color: isSelected ? AppColors.terracotta : AppColors.textSoft),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(opt.label,
                        style: GoogleFonts.inter(
                            fontSize: 15,
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
                        color: AppColors.terracotta, size: 22),
                ],
              ),
            ),
          );
        }),
        if (_dealbreakers.length >= 2)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Maximum 2 dealbreakers selected',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textMuted)),
          ),
      ],
    );
  }

  Widget _buildNavButtons() {
    final isLast = _step == _totalSteps;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              if (_step > 1) {
                setState(() => _step--);
              } else {
                context.go('/onboarding/photos');
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSoft,
              side: const BorderSide(color: AppColors.border, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text('Back',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    if (!isLast) {
                      setState(() => _step++);
                    } else {
                      _submit();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(
                    isLast ? "Find my roommate! 🎉" : 'Next →',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }
}
