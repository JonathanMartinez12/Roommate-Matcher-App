import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../features/swipe/screens/swipe_screen.dart';
import '../features/matches/screens/matches_screen.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../core/constants/app_colors.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/matches_provider.dart';
import 'dashboard_screen.dart';
import 'home_tab_provider.dart';

// ── Nav item descriptor ────────────────────────────────────────────────────
typedef _NavItem = ({
  IconData icon,
  IconData activeIcon,
  String label,
});

const List<_NavItem> _navItems = [
  (
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Home',
  ),
  (
    icon: Icons.explore_outlined,
    activeIcon: Icons.explore,
    label: 'Discover',
  ),
  (
    icon: Icons.favorite_outline,
    activeIcon: Icons.favorite,
    label: 'Matches',
  ),
  (
    icon: Icons.chat_bubble_outline,
    activeIcon: Icons.chat_bubble,
    label: 'Messages',
  ),
  (
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: 'Profile',
  ),
];

// ── Badge count provider ───────────────────────────────────────────────────
/// Returns the count of unread items for a given tab index.
/// Tab 2 = Matches, Tab 3 = Messages.
final _badgeCountProvider =
    Provider.family<int, int>((ref, tabIndex) {
  final currentUserId =
      ref.watch(authStateProvider).valueOrNull?.uid ?? '';
  final matches = ref.watch(matchesProvider).valueOrNull ?? [];

  if (tabIndex == 2) {
    // New (unread) matches
    return matches.where((m) => m.isUnread(currentUserId)).length;
  }
  if (tabIndex == 3) {
    // Conversations with unread messages
    return matches
        .where((m) => m.lastMessage != null && m.isUnread(currentUserId))
        .length;
  }
  return 0;
});

// ═══════════════════════════════════════════════════════════════════════════
// HomeScreen — root scaffold after authentication
// ═══════════════════════════════════════════════════════════════════════════
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Screens mapped 1-to-1 with _navItems
  static const List<Widget> _screens = [
    DashboardScreen(),
    SwipeScreen(),
    MatchesScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reset to the Home tab whenever the signed-in user changes (sign-out or
    // a different account signs in), so no stale tab state persists.
    ref.listen<UserModel?>(authNotifierProvider, (prev, next) {
      if (prev?.id != next?.id) {
        ref.read(homeTabIndexProvider.notifier).state = 0;
      }
    });

    final currentTab = ref.watch(homeTabIndexProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Row(
          children: [
            _SideNav(
              activeIndex: currentTab,
              onTap: (i) =>
                  ref.read(homeTabIndexProvider.notifier).state = i,
              onLogout: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go('/login');
              },
            ),
            Expanded(child: _screens[currentTab]),
          ],
        ),
      );
    }

    // ── Mobile: bottom navigation ─────────────────────────────────────────
    return Scaffold(
      body: IndexedStack(index: currentTab, children: _screens),
      bottomNavigationBar: _MobileBottomNav(
        currentIndex: currentTab,
        onTap: (i) => ref.read(homeTabIndexProvider.notifier).state = i,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Desktop sidebar navigation — exactly matches the HTML prototype
// ═══════════════════════════════════════════════════════════════════════════
class _SideNav extends ConsumerWidget {
  const _SideNav({
    required this.activeIndex,
    required this.onTap,
    required this.onLogout,
  });

  final int activeIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Container(
      width: 260,
      color: AppColors.navy,
      child: Column(
        children: [
          const SizedBox(height: 28),

          // ── Logo ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.terracotta,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'roomr',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // ── Nav items ─────────────────────────────────────────────────────
          ...List.generate(_navItems.length, (i) {
            final item = _navItems[i];
            final isActive = activeIndex == i;
            final badge = ref.watch(_badgeCountProvider(i));

            return GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 3,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.terracotta.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? AppColors.terracotta
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isActive ? item.activeIcon : item.icon,
                      size: 20,
                      color: isActive
                          ? Colors.white
                          : const Color(0xB3FFFFFF),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isActive
                              ? Colors.white
                              : const Color(0xB3FFFFFF),
                        ),
                      ),
                    ),
                    if (badge > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.terracotta,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$badge',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),

          const Spacer(),

          // ── User card at bottom ───────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(18),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.navySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _UserAvatar(
                      photoUrl: user?.photoUrls.isNotEmpty == true
                          ? user!.photoUrls.first
                          : null,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name.split(' ').first ?? 'You',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          if (user != null)
                            Text(
                              '${user.university} · ${user.major}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0x99FFFFFF),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onLogout,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Sign out',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xB3FFFFFF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Mobile bottom navigation bar
// ═══════════════════════════════════════════════════════════════════════════
class _MobileBottomNav extends ConsumerWidget {
  const _MobileBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navy,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final isActive = currentIndex == i;
              final badge = ref.watch(_badgeCountProvider(i));

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            isActive ? item.activeIcon : item.icon,
                            color: isActive
                                ? Colors.white
                                : const Color(0xB3FFFFFF),
                            size: 24,
                          ),
                          if (badge > 0)
                            Positioned(
                              top: -4,
                              right: -8,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: AppColors.terracotta,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '$badge',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive
                              ? Colors.white
                              : const Color(0xB3FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── User avatar helper ─────────────────────────────────────────────────────
class _UserAvatar extends StatelessWidget {
  const _UserAvatar({this.photoUrl, required this.size});

  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.navyLight,
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? CachedNetworkImage(imageUrl: photoUrl!, fit: BoxFit.cover)
          : const Icon(Icons.person, color: Colors.white54),
    );
  }
}
