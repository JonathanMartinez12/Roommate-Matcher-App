import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      backgroundColor: Colors.white,
      appBar: const RoomrAppBar(
        title: 'Messages',
        useGradientTitle: true,
      ),
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (matches) {
          final withMessages = matches.where((m) => m.lastMessage != null).toList();
          if (withMessages.isEmpty) return _buildEmptyState(matches.isEmpty);
          return ListView.separated(
            itemCount: withMessages.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
            itemBuilder: (ctx, i) => _ChatTile(
              match: withMessages[i],
              currentUserId: currentUserId,
              onTap: (user) => context.push(
                '/chat/${withMessages[i].id}?name=${Uri.encodeComponent(user.name)}&photo=${Uri.encodeComponent(user.photoUrls.isNotEmpty ? user.photoUrls.first : "")}',
              ),
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
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 52,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            noMatches ? 'No matches yet' : 'No messages yet',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            noMatches
                ? 'Start swiping to find your roommate!'
                : 'Say hi to your matches!',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  final MatchModel match;
  final String currentUserId;
  final void Function(UserModel) onTap;

  const _ChatTile({
    required this.match,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUserId = match.otherUserId(currentUserId);
    final userAsync = ref.watch(matchUserProvider(otherUserId));

    return userAsync.when(
      loading: () => const ListTile(
        leading: CircleAvatar(backgroundColor: Colors.grey),
        title: SizedBox(height: 12, width: 80, child: ColoredBox(color: Colors.grey)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final hasUnread = match.readStatus != null &&
            match.readStatus![currentUserId] == false;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.15),
            backgroundImage: user.photoUrls.isNotEmpty
                ? CachedNetworkImageProvider(user.photoUrls.first)
                : null,
            child: user.photoUrls.isEmpty
                ? Text(
                    user.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  )
                : null,
          ),
          title: Text(
            user.name,
            style: TextStyle(
              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            match.lastMessage ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hasUnread ? AppColors.primaryBlue : AppColors.textSecondary,
              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (match.lastMessageAt != null)
                Text(
                  timeago.format(match.lastMessageAt!),
                  style: TextStyle(
                    color: hasUnread ? AppColors.primaryBlue : AppColors.textHint,
                    fontSize: 11,
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              if (hasUnread)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          onTap: () => onTap(user),
        );
      },
    );
  }
}
