import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/swipe_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/seed_service.dart';
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

  Future<void> _blockUser(UserModel profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Block user?'),
        content: Text('${profile.firstName} will no longer appear in your discovery or matches.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(firestoreServiceProvider).blockUser(profile.id);
    ref.read(swipeProvider.notifier).pass(profile.id);
  }

  Future<void> _reportUser(UserModel profile) async {
    String? selectedCategory;
    final reasonCtrl = TextEditingController();
    final categories = ['Inappropriate photos', 'Harassment', 'Fake profile', 'Spam', 'Other'];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Report ${profile.firstName}',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy)),
              const SizedBox(height: 4),
              Text('Select a reason', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSoft)),
              const SizedBox(height: 16),
              ...categories.map((cat) => RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: cat,
                    groupValue: selectedCategory,
                    title: Text(cat, style: GoogleFonts.inter(fontSize: 14)),
                    onChanged: (v) => setModalState(() => selectedCategory = v),
                    activeColor: AppColors.terracotta,
                  )),
              const SizedBox(height: 8),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Additional details (optional)',
                  hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedCategory == null
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          await ref.read(firestoreServiceProvider).reportUser(
                                reportedUserId: profile.id,
                                category: selectedCategory!,
                                reason: reasonCtrl.text.trim(),
                              );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Report submitted. Thank you.')),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Submit Report', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    reasonCtrl.dispose();
  }

  Future<void> _handleSwipe(UserModel profile, CardSwiperDirection direction) async {
    final notifier = ref.read(swipeProvider.notifier);
    try {
      if (direction == CardSwiperDirection.right) {
        final isMatch = await notifier.like(profile.id);
        if (isMatch && mounted) {
          final uid = ref.read(authStateProvider).valueOrNull?.uid ?? '';
          final sorted = [uid, profile.id]..sort();
          setState(() {
            _matchedUser = profile;
            _matchId = '${sorted[0]}_${sorted[1]}';
            _showMatch = true;
          });
        }
      } else if (direction == CardSwiperDirection.left) {
        await notifier.pass(profile.id);
      }
    } catch (e) {
      debugPrint('[SwipeScreen] swipe error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Swipe error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final swipeState = ref.watch(swipeProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const RoomrAppBar(title: 'Discover', showLogo: true),
      body: Stack(
        children: [
          swipeState.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.terracotta)),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.textLight),
                  const SizedBox(height: 12),
                  Text('Error loading profiles', style: GoogleFonts.inter(color: AppColors.textSoft)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => ref.read(swipeProvider.notifier).loadProfiles(), child: const Text('Retry')),
                ],
              ),
            ),
            data: (profiles) {
              if (profiles.isEmpty) return _buildEmptyState();
              return _buildSwipeStack(profiles, currentUser);
            },
          ),
          if (_showMatch && _matchedUser != null && currentUser != null)
            Positioned.fill(
              child: MatchPopup(
                currentUser: currentUser,
                matchedUser: _matchedUser!,
                matchId: _matchId ?? '',
                onDismiss: () => setState(() { _showMatch = false; _matchedUser = null; }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSwipeStack(List<UserModel> profiles, UserModel? currentUser) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: CardSwiper(
              controller: _swiperController,
              cardsCount: profiles.length,
              numberOfCardsDisplayed: profiles.length > 1 ? 2 : 1,
              scale: 0.95,
              padding: const EdgeInsets.symmetric(vertical: 8),
              // Super-like has been removed — only horizontal swipes
              // (left = pass, right = like) are allowed. Disabling vertical
              // swipes prevents an upward drag from silently dismissing a
              // card with no backend effect.
              allowedSwipeDirection: const AllowedSwipeDirection.symmetric(
                horizontal: true,
              ),
              onSwipe: (prev, current, direction) {
                _handleSwipe(profiles[prev], direction);
                return true;
              },
              cardBuilder: (ctx, index, percentX, percentY) {
                if (index >= profiles.length) return const SizedBox.shrink();
                return Center(
                  child: SwipeCard(
                    user: profiles[index],
                    currentUser: currentUser,
                    isTop: index == 0,
                    onLike: () => _swiperController.swipe(CardSwiperDirection.right),
                    onPass: () => _swiperController.swipe(CardSwiperDirection.left),
                    onBlock: index == 0 ? () => _blockUser(profiles[index]) : null,
                    onReport: index == 0 ? () => _reportUser(profiles[index]) : null,
                  ),
                );
              },
            ),
          ),
        ),
        // Action buttons — pass (left) and like (right), centered.
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(
                icon: Icons.close,
                color: AppColors.pass,
                onTap: () => _swiperController.swipe(CardSwiperDirection.left),
                size: 56,
              ),
              const SizedBox(width: 56),
              _ActionButton(
                icon: Icons.favorite,
                color: AppColors.terracotta,
                onTap: () => _swiperController.swipe(CardSwiperDirection.right),
                size: 72,
                isPrimary: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _seeding = false;

  Future<void> _seedTestData() async {
    setState(() => _seeding = true);
    try {
      final uid = ref.read(authStateProvider).valueOrNull?.uid ?? '';
      await SeedService(uid).seedAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test data seeded! Refreshing...')),
        );
        ref.read(swipeProvider.notifier).loadProfiles();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seed error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: const BoxDecoration(color: AppColors.terracottaSoft, shape: BoxShape.circle),
              child: const Icon(Icons.people_outline, size: 52, color: AppColors.terracotta),
            ),
            const SizedBox(height: 20),
            Text('No profiles found', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.navy)),
            const SizedBox(height: 8),
            Text(
              'Make sure other accounts have completed onboarding (profile + quiz). You can also refresh to check for new users.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(swipeProvider.notifier).loadProfiles(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracotta,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _seeding ? null : _seedTestData,
                icon: _seeding
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.science_outlined),
                label: Text(_seeding ? 'Seeding...' : 'Seed test data'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSoft,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;
  final bool isPrimary;

  const _ActionButton({required this.icon, required this.color, required this.onTap, required this.size, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPrimary ? color : Colors.white,
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, spreadRadius: 2)],
        ),
        child: Icon(icon, color: isPrimary ? Colors.white : color, size: size * 0.45),
      ),
    );
  }
}
