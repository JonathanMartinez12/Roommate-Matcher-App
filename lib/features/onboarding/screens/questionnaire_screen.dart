import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/matching_service.dart';
import '../../../shared/widgets/gradient_button.dart';

class QuestionnaireScreen extends ConsumerStatefulWidget {
  const QuestionnaireScreen({super.key});
  @override
  ConsumerState<QuestionnaireScreen> createState() =>
      _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends ConsumerState<QuestionnaireScreen> {
  int _step = 1;
  static const int _totalSteps = 7;
  static const List<String> _stepLabels = [
    'Sleep',
    'Tidiness',
    'Noise',
    'Study',
    'Guests',
    'Lifestyle',
    'Dealbreakers',
  ];

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
  bool _showCelebration = false;
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _showCelebration = true;
    });
    _confetti.play();
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
      // Hold on celebration for a beat before routing.
      await Future.delayed(const Duration(milliseconds: 1600));
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(() => _showCelebration = false);
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
      body: Stack(
        children: [
          // Soft gradient halo behind everything
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.terracotta.withValues(alpha: 0.10),
                    AppColors.bg,
                  ],
                  center: const Alignment(-0.4, -0.8),
                  radius: 1.2,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 580),
                  padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.borderLight, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.08),
                        blurRadius: 40,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildProgress(),
                      const SizedBox(height: 28),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        transitionBuilder: (child, anim) {
                          final offset = Tween<Offset>(
                            begin: const Offset(0.08, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
                          return FadeTransition(
                            opacity: anim,
                            child: SlideTransition(position: offset, child: child),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey(_step),
                          child: _buildStepContent(),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildNavButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_showCelebration) _buildCelebrationOverlay(),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    final pct = _step / _totalSteps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.terracottaTint,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _stepLabels[_step - 1].toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.terracotta,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            Text('Step $_step / $_totalSteps',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 14),
        Stack(
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.creamDark,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) {
                return FractionallySizedBox(
                  widthFactor: v.clamp(0.0, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.terracotta.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
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
      case 4:
        return _buildChoice(
          question: "Where's your favourite study spot?",
          options: const [
            'Library — Need that quiet focus',
            'Coffee shops — Vibes matter',
            'Home — Comfort is key',
            'Flexible — wherever I end up',
          ],
          values: const ['library', 'cafe', 'at_home', 'flexible'],
          selected: _studyHabits,
          onSelect: (v) => setState(() => _studyHabits = v),
        );
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
      case 6:
        return _buildLifestyle();
      case 7:
        return _buildDealbreakers();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQuestionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTheme.displayStyle(
          fontSize: 28,
          letterSpacing: -0.6,
          height: 1.15,
        ),
      ),
    );
  }

  Widget _buildChoice({
    required String question,
    required List<String> options,
    required List<String> values,
    required String selected,
    required void Function(String) onSelect,
  }) {
    return Column(
      children: [
        if (question.isNotEmpty) _buildQuestionTitle(question),
        ...List.generate(options.length, (i) {
          final isSelected = selected == values[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ChoiceTile(
              label: options[i],
              selected: isSelected,
              onTap: () => onSelect(values[i]),
            )
                .animate(delay: Duration(milliseconds: 60 * i))
                .fadeIn(duration: 280.ms, curve: Curves.easeOut)
                .moveY(begin: 8, end: 0, duration: 320.ms, curve: Curves.easeOutCubic),
          );
        }),
      ],
    );
  }

  Widget _buildLifestyle() {
    return Column(
      children: [
        _buildQuestionTitle('Tell us about your lifestyle'),
        Text('Be honest — this helps find your best match',
            textAlign: TextAlign.center,
            style:
                GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted)),
        const SizedBox(height: 24),
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
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Temperature preference',
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy)),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (final v in const [
              ['cool', 'Cool'],
              ['moderate', 'Moderate'],
              ['warm', 'Warm']
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _SegmentChip(
                    label: v[1],
                    selected: _temperaturePreference == v[0],
                    onTap: () => setState(() => _temperaturePreference = v[0]),
                  ),
                ),
              ),
          ],
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
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: value ? AppColors.terracottaTint : AppColors.surface,
          border: Border.all(
            color: value ? AppColors.terracotta : AppColors.borderLight,
            width: value ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: AppColors.terracotta.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: value ? Colors.white : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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
        _buildQuestionTitle('Set your dealbreakers'),
        Text(
          'Pick up to 2. You will never be shown someone who triggers these.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        ...List.generate(kDealbreakerOptions.length, (i) {
          final opt = kDealbreakerOptions[i];
          final isSelected = _dealbreakers.contains(opt.key);
          final isDisabled = !isSelected && _dealbreakers.length >= 2;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DealbreakerTile(
              icon: opt.icon,
              label: opt.label,
              selected: isSelected,
              disabled: isDisabled,
              onTap: () => _toggleDealbreaker(opt.key),
            )
                .animate(delay: Duration(milliseconds: 50 * i))
                .fadeIn(duration: 240.ms)
                .moveY(begin: 6, end: 0, duration: 260.ms),
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
        SizedBox(
          width: 110,
          height: 56,
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
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('Back',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GradientButton(
            text: isLast ? "Find my roommate!" : 'Next',
            isLoading: _isLoading,
            isDark: !isLast,
            icon: isLast ? Icons.celebration_rounded : Icons.arrow_forward_rounded,
            onPressed: () {
              if (!isLast) {
                setState(() => _step++);
              } else {
                _submit();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCelebrationOverlay() {
    return Positioned.fill(
      child: Container(
        color: AppColors.navy.withValues(alpha: 0.86),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.05,
                numberOfParticles: 24,
                maxBlastForce: 22,
                minBlastForce: 8,
                gravity: 0.25,
                colors: const [
                  AppColors.terracotta,
                  AppColors.terracottaGlow,
                  AppColors.cream,
                  Colors.white,
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.terracotta.withValues(alpha: 0.5),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 64),
                )
                    .animate()
                    .scale(begin: const Offset(0.4, 0.4), end: const Offset(1, 1), duration: 520.ms, curve: Curves.elasticOut)
                    .fadeIn(duration: 240.ms),
                const SizedBox(height: 28),
                Text(
                  "You're all set!",
                  style: AppTheme.displayStyle(
                    fontSize: 36,
                    color: Colors.white,
                    letterSpacing: -1.0,
                  ),
                ).animate().fadeIn(delay: 220.ms, duration: 320.ms).moveY(begin: 12, end: 0),
                const SizedBox(height: 10),
                Text(
                  'Finding your people…',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 380.ms, duration: 320.ms),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: double.infinity,
        decoration: BoxDecoration(
          color: selected ? AppColors.terracottaTint : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.terracotta : AppColors.borderLight,
            width: selected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.terracotta.withValues(alpha: 0.20),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.terracotta : AppColors.text,
                ),
              ),
            ),
            AnimatedScale(
              scale: selected ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.terracotta, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.terracotta : AppColors.borderLight,
            width: selected ? 0 : 1.5,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.navy,
          ),
        ),
      ),
    );
  }
}

class _DealbreakerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _DealbreakerTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.terracottaTint
              : disabled
                  ? AppColors.surfaceAlt
                  : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.terracotta : AppColors.borderLight,
            width: selected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? Colors.white : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  size: 22,
                  color: selected ? AppColors.terracotta : AppColors.textSoft),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: disabled
                      ? AppColors.textLight
                      : selected
                          ? AppColors.terracotta
                          : AppColors.text,
                ),
              ),
            ),
            AnimatedScale(
              scale: selected ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.terracotta, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
