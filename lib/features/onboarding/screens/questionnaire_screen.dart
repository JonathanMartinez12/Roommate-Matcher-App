import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';

class QuestionnaireScreen extends ConsumerStatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  ConsumerState<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends ConsumerState<QuestionnaireScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  static const int _totalQuestions = 14;

  // Q1 – Friday night
  String _fridayNight = 'lowkey';
  // Q2 – Guests frequency
  String _guestsFrequency = 'monthly';
  // Q3 – Overnight guests
  String _overnightGuests = 'heads_up';
  // Q4 – Cleanliness (slider)
  int _cleanliness = 3;
  // Q5 – Sleep schedule
  String _sleepSchedule = 'flexible';
  // Q6 – Noise level
  String _noiseLevel = 'background';
  // Q7 – Morning routine
  String _morningRoutine = 'moderate';
  // Q8 – Kitchen habits
  String _kitchenHabits = 'reheat';
  // Q9 – Sharing comfort
  String _sharingComfort = 'some';
  // Q10 – Smoking
  bool _smoking = false;
  // Q11 – Drinking
  bool _drinking = false;
  // Q12 – Pets
  bool _pets = false;
  // Q13 – Rent budget
  String _rentBudget = '600_900';
  // Q14 – Home frequency
  String _homeFrequency = 'sometimes';

  void _nextPage() {
    if (_currentPage < _totalQuestions - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final userId = ref.read(authStateProvider).valueOrNull?.uid;
      if (userId == null) return;

      final questionnaire = Questionnaire(
        sleepSchedule: _sleepSchedule,
        cleanliness: _cleanliness,
        fridayNight: _fridayNight,
        guestsFrequency: _guestsFrequency,
        overnightGuests: _overnightGuests,
        noiseLevel: _noiseLevel,
        morningRoutine: _morningRoutine,
        kitchenHabits: _kitchenHabits,
        sharingComfort: _sharingComfort,
        rentBudget: _rentBudget,
        homeFrequency: _homeFrequency,
        smoking: _smoking,
        drinking: _drinking,
        pets: _pets,
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: _buildPages(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final progress = (_currentPage + 1) / _totalQuestions;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentPage > 0)
                GestureDetector(
                  onTap: _prevPage,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_rounded, size: 16, color: AppColors.textPrimary),
                  ),
                )
              else
                const SizedBox(width: 36),
              Expanded(
                child: Center(
                  child: Text(
                    'Question ${_currentPage + 1} of $_totalQuestions',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPages() {
    return [
      // Q1 – Friday night
      _buildChoicePage(
        category: 'Social Life',
        categoryColor: AppColors.socialColor,
        emoji: '🌙',
        question: 'What does your ideal Friday night look like?',
        options: const ['studying', 'lowkey', 'party'],
        labels: const ['Studying / Netflix 📚', 'Low-key hangout 🛋️', 'Party / going out 🎉'],
        selected: _fridayNight,
        onSelect: (v) => setState(() => _fridayNight = v),
      ),
      // Q2 – Guests frequency
      _buildChoicePage(
        category: 'Social Life',
        categoryColor: AppColors.socialColor,
        emoji: '🏠',
        question: 'How often would you have friends over?',
        options: const ['rarely', 'monthly', 'weekends', 'always'],
        labels: const ['Rarely', 'Once or twice a month', 'Most weekends', 'Basically live here'],
        selected: _guestsFrequency,
        onSelect: (v) => setState(() => _guestsFrequency = v),
      ),
      // Q3 – Overnight guests
      _buildChoicePage(
        category: 'Social Life',
        categoryColor: AppColors.socialColor,
        emoji: '🌛',
        question: 'Overnight guests (SO or friends) — how do you feel?',
        options: const ['prefer_not', 'heads_up', 'fine'],
        labels: const ['Prefer not 🚫', 'Heads-up appreciated 📩', 'Totally fine 👍'],
        selected: _overnightGuests,
        onSelect: (v) => setState(() => _overnightGuests = v),
      ),
      // Q4 – Cleanliness slider
      _buildSliderPage(
        category: 'Living Habits',
        categoryColor: AppColors.sleepColor,
        emoji: '🧹',
        question: 'How clean do you keep your space?',
        value: _cleanliness.toDouble(),
        min: 1, max: 5,
        minLabel: 'Messy',
        maxLabel: 'Spotless',
        onChanged: (v) => setState(() => _cleanliness = v.round()),
        accentColor: AppColors.sleepColor,
      ),
      // Q5 – Sleep schedule
      _buildChoicePage(
        category: 'Living Habits',
        categoryColor: AppColors.sleepColor,
        emoji: '😴',
        question: 'What\'s your sleep schedule like?',
        options: const ['early_bird', 'flexible', 'night_owl'],
        labels: const ['Early bird 🌅\n(asleep before 11)', 'Flexible 😊', 'Night owl 🦉\n(up past 1am)'],
        selected: _sleepSchedule,
        onSelect: (v) => setState(() => _sleepSchedule = v),
      ),
      // Q6 – Noise level
      _buildChoicePage(
        category: 'Living Habits',
        categoryColor: AppColors.sleepColor,
        emoji: '🔊',
        question: 'How loud is your space usually?',
        options: const ['quiet', 'background', 'lively'],
        labels: const ['Quiet 🎧\n(headphones only)', 'Background music 🎵', 'I like it lively 🎉'],
        selected: _noiseLevel,
        onSelect: (v) => setState(() => _noiseLevel = v),
      ),
      // Q7 – Morning routine
      _buildChoicePage(
        category: 'Living Habits',
        categoryColor: AppColors.sleepColor,
        emoji: '🚿',
        question: 'How long is your morning routine?',
        options: const ['quick', 'moderate', 'long'],
        labels: const ['Quick ⚡\n(< 20 min)', 'Moderate ☕\n(~30 min)', 'I need the bathroom 🛁\n(45 min+)'],
        selected: _morningRoutine,
        onSelect: (v) => setState(() => _morningRoutine = v),
      ),
      // Q8 – Kitchen habits
      _buildChoicePage(
        category: 'Kitchen & Sharing',
        categoryColor: AppColors.kitchenColor,
        emoji: '🍳',
        question: 'What are your kitchen habits?',
        options: const ['cook', 'reheat', 'eat_out'],
        labels: const ['I cook often 🍳', 'Heat things up 🥡', 'DoorDash is bae 🛵'],
        selected: _kitchenHabits,
        onSelect: (v) => setState(() => _kitchenHabits = v),
      ),
      // Q9 – Sharing comfort
      _buildChoicePage(
        category: 'Kitchen & Sharing',
        categoryColor: AppColors.kitchenColor,
        emoji: '🤝',
        question: 'How do you feel about sharing household stuff?',
        options: const ['separate', 'some', 'share'],
        labels: const ['Keep everything separate 🔒', 'Some sharing is fine 👌', 'Love a shared house ❤️'],
        selected: _sharingComfort,
        onSelect: (v) => setState(() => _sharingComfort = v),
      ),
      // Q10 – Smoking
      _buildTogglePage(
        category: 'Lifestyle',
        categoryColor: AppColors.lifestyleColor,
        emoji: '🚬',
        question: 'Is smoking OK in the space?',
        value: _smoking,
        onChanged: (v) => setState(() => _smoking = v),
        accentColor: AppColors.lifestyleColor,
      ),
      // Q11 – Drinking
      _buildTogglePage(
        category: 'Lifestyle',
        categoryColor: AppColors.lifestyleColor,
        emoji: '🍻',
        question: 'Is social drinking OK?',
        value: _drinking,
        onChanged: (v) => setState(() => _drinking = v),
        accentColor: AppColors.lifestyleColor,
      ),
      // Q12 – Pets
      _buildTogglePage(
        category: 'Lifestyle',
        categoryColor: AppColors.lifestyleColor,
        emoji: '🐾',
        question: 'Are pets OK with you?',
        value: _pets,
        onChanged: (v) => setState(() => _pets = v),
        accentColor: AppColors.lifestyleColor,
      ),
      // Q13 – Rent budget
      _buildChoicePage(
        category: 'Bonus',
        categoryColor: AppColors.highlight,
        emoji: '💰',
        question: 'What\'s your monthly rent budget?',
        options: const ['under_600', '600_900', '900_1200', '1200_plus'],
        labels: const ['Under \$600', '\$600 – \$900', '\$900 – \$1,200', '\$1,200+'],
        selected: _rentBudget,
        onSelect: (v) => setState(() => _rentBudget = v),
      ),
      // Q14 – Home frequency
      _buildChoicePage(
        category: 'Bonus',
        categoryColor: AppColors.highlight,
        emoji: '💻',
        question: 'How often do you study / work from home?',
        options: const ['rarely', 'sometimes', 'often'],
        labels: const ['Rarely home during the day 🏃', 'Sometimes WFH 🏠', 'Almost always home 💻'],
        selected: _homeFrequency,
        onSelect: (v) => setState(() => _homeFrequency = v),
      ),
    ];
  }

  Widget _buildChoicePage({
    required String category,
    required Color categoryColor,
    required String emoji,
    required String question,
    required List<String> options,
    required List<String> labels,
    required String selected,
    required void Function(String) onSelect,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              category,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: categoryColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Emoji
          Text(emoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 14),

          // Question
          Text(
            question,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 28),

          // Options
          ...List.generate(options.length, (i) {
            final isSelected = selected == options[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  onSelect(options[i]);
                  Future.delayed(const Duration(milliseconds: 200), _nextPage);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? categoryColor.withValues(alpha: 0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? categoryColor : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: categoryColor.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? categoryColor : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? categoryColor : AppColors.border,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? categoryColor : AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSliderPage({
    required String category,
    required Color categoryColor,
    required String emoji,
    required String question,
    required double value,
    required double min,
    required double max,
    required String minLabel,
    required String maxLabel,
    required void Function(double) onChanged,
    required Color accentColor,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              category,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: categoryColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(emoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 14),
          Text(
            question,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 40),

          // Score display
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [accentColor.withValues(alpha: 0.2), accentColor.withValues(alpha: 0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: accentColor, width: 3),
              ),
              child: Center(
                child: Text(
                  value.round().toString(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.12),
              inactiveTrackColor: AppColors.border,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
              trackHeight: 6,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              onChanged: onChanged,
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(minLabel, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                Text(maxLabel, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),

          const SizedBox(height: 48),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildTogglePage({
    required String category,
    required Color categoryColor,
    required String emoji,
    required String question,
    required bool value,
    required void Function(bool) onChanged,
    required Color accentColor,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              category,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: categoryColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(emoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 14),
          Text(
            question,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 32),

          // Yes / No cards
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    onChanged(true);
                    Future.delayed(const Duration(milliseconds: 200), _nextPage);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 120,
                    decoration: BoxDecoration(
                      color: value
                          ? accentColor.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: value ? accentColor : AppColors.border,
                        width: value ? 2.5 : 1,
                      ),
                      boxShadow: value
                          ? [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('✅', style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(
                          'Yes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: value ? accentColor : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    onChanged(false);
                    Future.delayed(const Duration(milliseconds: 200), _nextPage);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 120,
                    decoration: BoxDecoration(
                      color: !value
                          ? AppColors.pass.withValues(alpha: 0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: !value ? AppColors.pass : AppColors.border,
                        width: !value ? 2.5 : 1,
                      ),
                      boxShadow: !value
                          ? [
                              BoxShadow(
                                color: AppColors.pass.withValues(alpha: 0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('❌', style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(
                          'No',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: !value ? AppColors.pass : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    final isLast = _currentPage == _totalQuestions - 1;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _nextPage,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  isLast ? '🎉  Find My Roommate!' : 'Next →',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
