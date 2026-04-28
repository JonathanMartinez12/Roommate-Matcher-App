import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/app_colors.dart';
import '../models/match_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/matches_provider.dart';
import 'home_tab_provider.dart';

// ── Tab index constants ────────────────────────────────────────────────────
const int kTabDiscover = 1;
const int kTabMatches = 2;
const int kTabProfile = 4;

// ── Tip data ──────────────────────────────────────────────────────────────
const _tips = [
  (
    title: 'Complete your profile',
    description: 'Profiles with photos get 3× more matches!',
    image:
        'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?w=400&h=300&fit=crop',
  ),
  (
    title: 'Be specific in your bio',
    description: 'Mention hobbies, study habits, and deal breakers.',
    image:
        'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=400&h=300&fit=crop',
  ),
  (
    title: 'Start conversations',
    description: "Don't wait — send a message to your matches!",
    image:
        'https://images.unsplash.com/photo-1521737711867-e3b97375f902?w=400&h=300&fit=crop',
  ),
];

// ── Entry widget ─────────────────────────────────────────────────────────
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final currentUserId =
        ref.watch(authStateProvider).valueOrNull?.uid ?? '';

    final profileViews =
        ref.watch(profileViewsProvider).valueOrNull ?? (total: 0, thisWeek: 0);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: matchesAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.terracotta)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (matches) {
          final totalMatches = matches.length;
          final unreadCount =
              matches.where((m) => m.isUnread(currentUserId)).length;
          final recentMatches = matches.take(3).toList();

          final scoredMatches =
              matches.where((m) => m.compatibilityScore > 0).toList();
          final avgCompat = scoredMatches.isEmpty
              ? 0
              : (scoredMatches
                          .map((m) => m.compatibilityScore)
                          .reduce((a, b) => a + b) /
                      scoredMatches.length)
                  .round();

          final isDesktop = MediaQuery.of(context).size.width >= 800;

          return isDesktop
              ? _DesktopDashboard(
                  user: user,
                  totalMatches: totalMatches,
                  unreadCount: unreadCount,
                  recentMatches: recentMatches,
                  avgCompat: avgCompat,
                  currentUserId: currentUserId,
                  profileViews: profileViews,
                )
              : _MobileDashboard(
                  user: user,
                  totalMatches: totalMatches,
                  unreadCount: unreadCount,
                  recentMatches: recentMatches,
                  avgCompat: avgCompat,
                  currentUserId: currentUserId,
                  profileViews: profileViews,
                );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DESKTOP LAYOUT  (≥ 800 px)
// Matches the prototype: greeting header → stats row → 2-col main grid
// ═══════════════════════════════════════════════════════════════════════════
class _DesktopDashboard extends ConsumerWidget {
  const _DesktopDashboard({
    required this.user,
    required this.totalMatches,
    required this.unreadCount,
    required this.recentMatches,
    required this.avgCompat,
    required this.currentUserId,
    required this.profileViews,
  });

  final UserModel? user;
  final int totalMatches;
  final int unreadCount;
  final List<MatchModel> recentMatches;
  final int avgCompat;
  final String currentUserId;
  final ProfileViewStats profileViews;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(48, 40, 48, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          _DashHeader(user: user),
          const SizedBox(height: 36),

          // ── Stats row ────────────────────────────────────────────────────
          // IntrinsicHeight + stretch makes all four cards take the height
          // of the tallest one — otherwise the Avg. compatibility / Unread
          // messages cards (which sometimes have no subtext line) render
          // shorter than the others.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Expanded(
                child: _StatCard(
                  iconData: Icons.visibility_outlined,
                  iconColor: AppColors.terracotta,
                  value: '${profileViews.total}',
                  label: 'Profile views',
                  subtext: profileViews.thisWeek > 0
                      ? '↑ ${profileViews.thisWeek} this week'
                      : null,
                  accentColor: AppColors.terracottaSoft,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _StatCard(
                  iconData: Icons.favorite_outline,
                  iconColor: const Color(0xFF8B5CF6),
                  value: '$totalMatches',
                  label: 'Total matches',
                  subtext: totalMatches > 0 ? '$totalMatches new!' : null,
                  accentColor: const Color(0x268B5CF6),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _StatCard(
                  iconData: Icons.chat_bubble_outline,
                  iconColor: const Color(0xFF22C55E),
                  value: '$unreadCount',
                  label: 'Unread messages',
                  subtext: unreadCount > 0 ? '$unreadCount unread' : null,
                  accentColor: const Color(0x2622C55E),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _StatCard(
                  iconData: Icons.trending_up,
                  iconColor: const Color(0xFFFBBF24),
                  value: avgCompat > 0 ? '$avgCompat%' : '--',
                  label: 'Avg. compatibility',
                  accentColor: const Color(0x26FBBF24),
                ),
              ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Two-column grid ──────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column — Quick actions + Recent matches
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _QuickActions(),
                    const SizedBox(height: 32),
                    _RecentMatchesSection(
                      matches: recentMatches,
                      currentUserId: currentUserId,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),

              // Right column — Tips + Campus banner (fixed 380 px)
              SizedBox(
                width: 380,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tips for you',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._tips.map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TipCard(
                            title: t.title,
                            description: t.description,
                            imageUrl: t.image,
                          ),
                        )),
                    const SizedBox(height: 24),
                    const _CampusBanner(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MOBILE LAYOUT  (< 800 px)
// Single-column, scrollable — denser information layout
// ═══════════════════════════════════════════════════════════════════════════
class _MobileDashboard extends ConsumerWidget {
  const _MobileDashboard({
    required this.user,
    required this.totalMatches,
    required this.unreadCount,
    required this.recentMatches,
    required this.avgCompat,
    required this.currentUserId,
    required this.profileViews,
  });

  final UserModel? user;
  final int totalMatches;
  final int unreadCount;
  final List<MatchModel> recentMatches;
  final int avgCompat;
  final String currentUserId;
  final ProfileViewStats profileViews;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashHeader(user: user),
          const SizedBox(height: 24),

          // Stats — 2×2 grid using Wrap
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: (MediaQuery.of(context).size.width - 52) / 2,
                child: _StatCard(
                  iconData: Icons.visibility_outlined,
                  iconColor: AppColors.terracotta,
                  value: '${profileViews.total}',
                  label: 'Profile views',
                  subtext: profileViews.thisWeek > 0
                      ? '↑ ${profileViews.thisWeek} this week'
                      : null,
                  accentColor: AppColors.terracottaSoft,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 52) / 2,
                child: _StatCard(
                  iconData: Icons.favorite_outline,
                  iconColor: const Color(0xFF8B5CF6),
                  value: '$totalMatches',
                  label: 'Total matches',
                  subtext: totalMatches > 0 ? '$totalMatches new!' : null,
                  accentColor: const Color(0x268B5CF6),
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 52) / 2,
                child: _StatCard(
                  iconData: Icons.chat_bubble_outline,
                  iconColor: const Color(0xFF22C55E),
                  value: '$unreadCount',
                  label: 'Unread messages',
                  subtext: unreadCount > 0 ? '$unreadCount unread' : null,
                  accentColor: const Color(0x2622C55E),
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 52) / 2,
                child: _StatCard(
                  iconData: Icons.trending_up,
                  iconColor: const Color(0xFFFBBF24),
                  value: avgCompat > 0 ? '$avgCompat%' : '--',
                  label: 'Avg. compat.',
                  accentColor: const Color(0x26FBBF24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const _QuickActions(),
          const SizedBox(height: 28),

          _RecentMatchesSection(
            matches: recentMatches,
            currentUserId: currentUserId,
          ),
          const SizedBox(height: 28),

          Text(
            'Tips for you',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 16),
          ..._tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TipCard(
                  title: t.title,
                  description: t.description,
                  imageUrl: t.image,
                ),
              )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED COMPONENT WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

// ── Dashboard header ───────────────────────────────────────────────────────
class _DashHeader extends StatelessWidget {
  const _DashHeader({required this.user});
  final UserModel? user;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = user?.name.split(' ').first ?? 'there';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_greeting, $firstName',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Here's what's happening with your roommate search",
          style: GoogleFonts.inter(fontSize: 16, color: AppColors.textSoft),
        ),
      ],
    );
  }
}

// ── Stat card ──────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.iconData,
    required this.iconColor,
    required this.value,
    required this.label,
    this.subtext,
    required this.accentColor,
  });

  final IconData iconData;
  final Color iconColor;
  final String value;
  final String label;
  final String? subtext;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(iconData, size: 28, color: iconColor),
              const SizedBox(height: 12),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
              if (subtext != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtext!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.terracotta,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quick actions ──────────────────────────────────────────────────────────
class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick actions',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _ActionChip(
              label: 'Find roommates',
              isPrimary: true,
              onTap: () => ref.read(homeTabIndexProvider.notifier).state =
                  kTabDiscover,
            ),
            _ActionChip(
              label: 'View matches',
              onTap: () => ref.read(homeTabIndexProvider.notifier).state =
                  kTabMatches,
            ),
            _ActionChip(
              label: 'Edit profile',
              onTap: () =>
                  ref.read(homeTabIndexProvider.notifier).state = kTabProfile,
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.terracotta : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: isPrimary
              ? null
              : Border.all(color: AppColors.border, width: 1.5),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.terracotta.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isPrimary ? Colors.white : AppColors.text,
          ),
        ),
      ),
    );
  }
}

// ── Recent matches section ─────────────────────────────────────────────────
class _RecentMatchesSection extends ConsumerWidget {
  const _RecentMatchesSection({
    required this.matches,
    required this.currentUserId,
  });

  final List<MatchModel> matches;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (matches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent matches',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            GestureDetector(
              onTap: () =>
                  ref.read(homeTabIndexProvider.notifier).state = kTabMatches,
              child: Text(
                'View all →',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.terracotta,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Responsive grid: 3 cols on desktop, 2 cols on mobile
        LayoutBuilder(
          builder: (ctx, constraints) {
            final crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;
            final itemWidth =
                (constraints.maxWidth - (crossAxisCount - 1) * 16) /
                    crossAxisCount;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: matches
                  .map((m) => SizedBox(
                        width: itemWidth,
                        child: _DashMatchTile(
                          match: m,
                          currentUserId: currentUserId,
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

// ── Individual match tile for dashboard ────────────────────────────────────
class _DashMatchTile extends ConsumerWidget {
  const _DashMatchTile({
    required this.match,
    required this.currentUserId,
  });

  final MatchModel match;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUserId = match.otherUserId(currentUserId);
    final userAsync = ref.watch(matchUserProvider(otherUserId));

    return userAsync.when(
      loading: () => Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.creamLight,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => context.push(
            '/chat/${match.id}?name=${Uri.encodeComponent(user.name)}'
            '&photo=${Uri.encodeComponent(user.photoUrls.isNotEmpty ? user.photoUrls.first : "")}'
            '&userId=${user.id}',
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Photo
                SizedBox(
                  height: 140,
                  child: user.photoUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: user.photoUrls.first,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _PlaceholderAvatar(
                              name: user.name),
                        )
                      : _PlaceholderAvatar(name: user.name),
                ),
                // Info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.major,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (match.compatibilityScore > 0) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.terracottaSoft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${match.compatibilityScore}% match',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.terracotta,
                            ),
                          ),
                        ),
                      ],
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

class _PlaceholderAvatar extends StatelessWidget {
  const _PlaceholderAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.terracottaSoft,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.inter(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: AppColors.terracotta,
          ),
        ),
      ),
    );
  }
}

// ── Tip card ───────────────────────────────────────────────────────────────
class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  final String title;
  final String description;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            SizedBox(
              width: 110,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    Container(color: AppColors.terracottaSoft),
              ),
            ),
            // Text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Campus banner ──────────────────────────────────────────────────────────
class _CampusBanner extends StatelessWidget {
  const _CampusBanner();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 180,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl:
                  'https://images.unsplash.com/photo-1562774053-701939374585'
                  '?w=800&h=600&fit=crop',
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  Container(color: AppColors.navyLight),
            ),
            // Gradient overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.navy.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Text(
                '5,000+ students have found roommates on Roomr',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
