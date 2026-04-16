import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/match_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/matches_provider.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesProvider);
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const RoomrAppBar(title: 'Matches'),
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.terracotta)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (matches) {
          if (matches.isEmpty) return _buildEmptyState();
          return _buildContent(context, ref, matches, currentUserId);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<MatchModel> matches, String currentUserId) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your matches',
                  style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.navy)),
                const SizedBox(height: 6),
                Text('People who are also interested in rooming with you',
                  style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSoft)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final match = matches[i];
                final otherUserId = match.otherUserId(currentUserId);
                return _MatchCard(
                  match: match,
                  otherUserId: otherUserId,
                  ref: ref,
                  onTap: (user) => context.push(
                    '/chat/${match.id}?name=${Uri.encodeComponent(user.name)}&photo=${Uri.encodeComponent(user.photoUrls.isNotEmpty ? user.photoUrls.first : "")}&userId=${user.id}',
                  ),
                );
              },
              childCount: matches.length,
            ),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: const BoxDecoration(color: AppColors.terracottaSoft, shape: BoxShape.circle),
            child: const Icon(Icons.favorite_outline, size: 52, color: AppColors.terracotta),
          ),
          const SizedBox(height: 20),
          Text('No matches yet', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.navy)),
          const SizedBox(height: 8),
          Text('Keep swiping to find your roommate!', style: GoogleFonts.inter(fontSize: 15, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final MatchModel match;
  final String otherUserId;
  final WidgetRef ref;
  final void Function(UserModel) onTap;

  const _MatchCard({required this.match, required this.otherUserId, required this.ref, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(matchUserProvider(otherUserId));
    return userAsync.when(
      loading: () => const _SkeletonCard(),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => onTap(user),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2))],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: user.photoUrls.isNotEmpty
                      ? CachedNetworkImage(imageUrl: user.photoUrls.first, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.terracottaSoft,
                          child: Center(child: Text(
                            user.name.isNotEmpty ? user.name[0] : '?',
                            style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.terracotta),
                          )),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.navy)),
                      const SizedBox(height: 4),
                      Text(user.major, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                      const SizedBox(height: 10),
                      if (match.compatibilityScore > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(color: AppColors.terracottaSoft, borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            '${match.compatibilityScore}% match',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.terracotta),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.creamLight, borderRadius: BorderRadius.circular(20)),
    );
  }
}
