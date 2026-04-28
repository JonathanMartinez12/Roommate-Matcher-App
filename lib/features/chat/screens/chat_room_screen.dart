import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/matches_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/notification_service.dart';
import '../widgets/icebreaker_dialog.dart';
import '../widgets/message_bubble.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String matchedUserName;
  final String matchedUserPhoto;
  final String matchedUserId;

  const ChatRoomScreen(
      {super.key,
      required this.matchId,
      required this.matchedUserName,
      required this.matchedUserPhoto,
      required this.matchedUserId});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatNotifierProvider(widget.matchId).notifier).markRead();
      // Tell the server + local FCM handler that this chat is now focused,
      // so message pushes for it are suppressed.
      ref.read(activeChatIdProvider.notifier).state = widget.matchId;
      ref.read(firestoreServiceProvider).setActiveChatId(widget.matchId);
    });
  }

  @override
  void dispose() {
    // Best-effort clear; don't await since dispose is synchronous.
    ref.read(activeChatIdProvider.notifier).state = null;
    ref.read(firestoreServiceProvider).setActiveChatId(null);
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _blockUser(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Block user?'),
        content: Text('${widget.matchedUserName} will no longer be able to contact you or appear in your matches.'),
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
    await ref.read(firestoreServiceProvider).blockUser(widget.matchedUserId);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _reportUser(BuildContext context) async {
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
              Text('Report ${widget.matchedUserName}',
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
                                reportedUserId: widget.matchedUserId,
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

  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    await ref
        .read(chatNotifierProvider(widget.matchId).notifier)
        .sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _openIcebreaker() async {
    final me = ref.read(currentUserProvider).valueOrNull;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading your profile, try again in a moment.')),
      );
      return;
    }
    // Pull the matched user's profile (cached by FutureProvider). If it's
    // not ready yet we still let the dialog open with `null` and the
    // service will fall back to generic prompts.
    final other =
        ref.read(matchUserProvider(widget.matchedUserId)).valueOrNull;

    final result = await IcebreakerDialog.show(
      context,
      me: me,
      other: other,
    );
    if (result == null || !mounted) return;
    final trimmed = result.trim();
    if (trimmed.isEmpty) return;
    await ref
        .read(chatNotifierProvider(widget.matchId).notifier)
        .sendMessage(trimmed);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.matchId));
    final isSending = ref.watch(chatNotifierProvider(widget.matchId));
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          color: Colors.white,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.arrow_back,
                          color: AppColors.textSoft, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    clipBehavior: Clip.antiAlias,
                    child: widget.matchedUserPhoto.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.matchedUserPhoto,
                            fit: BoxFit.cover)
                        : Container(
                            color: AppColors.terracottaSoft,
                            child: Center(
                                child: Text(
                              widget.matchedUserName.isNotEmpty
                                  ? widget.matchedUserName[0]
                                  : '?',
                              style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.terracotta),
                            )),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.matchedUserName,
                            style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navy)),
Builder(builder: (_) {
  final userAsync = ref.watch(matchUserProvider(widget.matchedUserId));
  return userAsync.when(
    loading: () => const SizedBox.shrink(),
    error: (_, __) => const SizedBox.shrink(),
    data: (user) {
      final lastActive = user?.lastActiveAt;
      final isOnline = lastActive != null &&
          DateTime.now().difference(lastActive).inMinutes < 5;
      return Text(
        isOnline
            ? 'Online'
            : lastActive != null
                ? 'Last seen ${timeago.format(lastActive)}'
                : 'Offline',
        style: GoogleFonts.inter(
            fontSize: 12,
            color: isOnline ? Colors.green : AppColors.textMuted),
      );
    },
  );
}),

                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.textSoft),
                    onSelected: (value) {
                      if (value == 'block') _blockUser(context);
                      if (value == 'report') _reportUser(context);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'block',
                        child: Row(children: [
                          Icon(Icons.block, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Block user'),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: 'report',
                        child: Row(children: [
                          Icon(Icons.flag_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Report user'),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.terracotta)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (messages) {
                if (messages.isEmpty) return _buildEmptyChat();
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(28),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == currentUserId;
                    final showTime = i == messages.length - 1 ||
                        messages[i + 1]
                                .createdAt
                                .difference(msg.createdAt)
                                .inMinutes >
                            5;
                    return MessageBubble(
                        message: msg, isMe: isMe, showTime: showTime);
                  },
                );
              },
            ),
          ),
          _buildInputBar(isSending),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.waving_hand_outlined, size: 48, color: AppColors.terracotta),
          const SizedBox(height: 12),
          Text('Say hello!',
              style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy)),
          const SizedBox(height: 6),
          Text(
            'You matched with ${widget.matchedUserName}.\nBreak the ice!',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppColors.textSoft, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isSending) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: isSending ? null : _openIcebreaker,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.terracottaSoft,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.terracotta.withValues(alpha: 0.4),
                    width: 1.5),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.terracotta,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight, width: 2),
              ),
              child: TextField(
                controller: _textCtrl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: 4,
                minLines: 1,
                style: GoogleFonts.inter(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.inter(
                      color: AppColors.textMuted, fontSize: 15),
                  filled: false,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: isSending ? null : _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.terracotta,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.terracotta.withValues(alpha: 0.3),
                      blurRadius: 8)
                ],
              ),
              child: isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
