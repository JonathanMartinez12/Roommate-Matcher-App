import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/swipe_provider.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../widgets/swipe_card.dart';
import '../widgets/match_popup.dart';

class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key});

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen> {
  final CardSwiperController _swiperController = CardSwiperController();
  bool _showMatch = false;
  UserModel? _matchedUser;
  String? _matchId;

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> _handleSwipe(
    UserModel profile,
    CardSwiperDirection direction,
  ) async {
    final notifier = ref.read(swipeProvider.notifier);

    if (direction == CardSwiperDirection.right) {
      final isMatch = await notifier.like(profile.id);
      if (isMatch && mounted) {
        // Find the match ID from Firestore — simplification: show popup with profile
        setState(() {
          _matchedUser = profile;
          _matchId = '\${ref.read(authStateProvider).valueOrNull?.uid}_\${profile.id}';
          _showMatch = true;
        });
      }
    } else if (direction == CardSwiperDirection.left) {
      await notifier.pass(profile.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final swipeState = ref.watch(swipeProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: const RoomrAppBar(
        title: 'Roomr',
        useGradientTitle: true,
      ),
      body: Stack(
        children: [
          swipeState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text('Error loading profiles', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(swipeProvider.notifier).loadProfiles(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (profiles) {
              if (profiles.isEmpty) return _buildEmptyState();
              return _buildSwipeStack(profiles, currentUser);
            },
          ),
          if (_showMatch && _matchedUser != null && currentUser != null)
            _buildMatchOverlay(currentUser),
        ],
      ),
    );
  }

  Widget _buildSwipeStack(List<UserModel> profiles, UserModel? currentUser) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: CardSwiper(
              controller: _swiperController,
              cardsCount: profiles.length,
              numberOfCardsDisplayed: profiles.length > 2 ? 3 : profiles.length,
              backCardOffset: const Offset(0, 16),
              padding: const EdgeInsets.all(0),
              onSwipe: (prevIndex, currentIndex, direction) {
                _handleSwipe(profiles[prevIndex], direction);
                return true;
              },
              cardBuilder: (context, index, percentThrown, percentOpacity) {
                return SwipeCard(
                  user: profiles[index],
                  currentUser: currentUser,
                  isTop: index == 0,
                );
              },
            ),
          ),
        ),
        _buildActionButtons(profiles),
      ],
    );
  }

  Widget _buildActionButtons(List<UserModel> profiles) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 12, 40, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Pass button
          _ActionButton(
            icon: Icons.close_rounded,
            color: AppColors.pass,
            size: 60,
            iconSize: 32,
            onTap: () => _swiperController.swipe(CardSwiperDirection.left),
          ),
          // Super like
          _ActionButton(
            icon: Icons.star_rounded,
            color: AppColors.primaryBlue,
            size: 46,
            iconSize: 24,
            onTap: () => _swiperController.swipe(CardSwiperDirection.top),
          ),
          // Like button
          _ActionButton(
            icon: Icons.favorite_rounded,
            color: AppColors.like,
            size: 60,
            iconSize: 32,
            onTap: () => _swiperController.swipe(CardSwiperDirection.right),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.explore_outlined,
              size: 52,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "You've seen everyone!",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later for new roommates',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.read(swipeProvider.notifier).loadProfiles(),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchOverlay(UserModel currentUser) {
    return Positioned.fill(
      child: MatchPopup(
        currentUser: currentUser,
        matchedUser: _matchedUser!,
        matchId: _matchId ?? '',
        onDismiss: () => setState(() {
          _showMatch = false;
          _matchedUser = null;
          _matchId = null;
        }),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: iconSize),
      ),
    );
  }
}
