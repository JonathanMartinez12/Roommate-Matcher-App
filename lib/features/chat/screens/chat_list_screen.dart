import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_colors.dart';
import '../../../models/match_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/matches_provider.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesProvider);
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const RoomrAppBar(title: 'Messages', showLogo: true),
      body: matchesAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.terracotta)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (matches) {
          final withMessages =
              matches.where((m) => m.lastMessage != null).toList();
          if (withMessages.isEmpty) return _buildEmptyState(matches.isEmpty);
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${withMessages.length} conversations',
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 14)),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: withMessages.length,
                    itemBuilder: (ctx, i) => _ChatTile(
                      match: withMessages[i],
                      currentUserId: currentUserId,
                      onTap: (user) => context.push(
                        '/chat/${withMessages[i].id}?name=${Uri.encodeComponent(user.name)}&photo=${Uri.encodeComponent(user.photoUrls.isNotEmpty ? user.photoUrls.first : "")}&userId=${user.id}',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool noMatches) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
                color: AppColors.terracottaSoft, shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_outline,
                size: 52, color: AppColors.terracotta),
          ),
          const SizedBox(height: 20),
          Text(noMatches ? 'No matches yet' : 'No messages yet',
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy)),
          const SizedBox(height: 8),
          Text(
              noMatches
                  ? 'Start swiping to find your roommate!'
                  : 'Say hi to your matches!',
              style:
                  GoogleFonts.inter(fontSize: 15, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  final MatchModel match;
  final String currentUserId;
  final void Function(UserModel user) onTap;

  const _ChatTile(
      {required this.match, required this.currentUserId, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUserId = match.otherUserId(currentUserId);
    final userAsync = ref.watch(matchUserProvider(otherUserId));
    final hasUnread = match.isUnread(currentUserId);

    return userAsync.when(
      loading: () => const SizedBox(height: 80),
      error: (_, __) => const SizedBox(),
      data: (user) {
        if (user == null) return const SizedBox();
        return GestureDetector(
          onTap: () => onTap(user),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)
              ],
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  clipBehavior: Clip.antiAlias,
                  child: user.photoUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: user.photoUrls.first, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.terracottaSoft,
                          child: Center(
                              child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.terracotta),
                          )),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: hasUnread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: AppColors.navy),
                            ),
                          ),
                          if (match.lastMessageAt != null)
                            Text(
                              timeago.format(match.lastMessageAt!),
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.textMuted),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        match.lastMessage ?? '',
                        style: GoogleFonts.inter(
                            fontSize: 14, color: AppColors.textSoft),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (hasUnread) ...[
                  const SizedBox(width: 12),
                  Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                          color: AppColors.terracotta, shape: BoxShape.circle)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
