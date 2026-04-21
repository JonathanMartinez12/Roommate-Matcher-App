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
import '../../../services/firestore_service.dart';
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

class _MatchCard extends ConsumerWidget {
  final MatchModel match;
  final String otherUserId;
  final void Function(UserModel) onTap;

  const _MatchCard({required this.match, required this.otherUserId, required this.onTap});

  Future<void> _blockUser(BuildContext context, WidgetRef ref, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Block user?'),
        content: Text('$userName will no longer appear in your matches or be able to contact you.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(firestoreServiceProvider).blockUser(otherUserId);
  }

  Future<void> _reportUser(BuildContext context, WidgetRef ref, String userName) async {
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
              Text('Report $userName',
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
                                reportedUserId: otherUserId,
                                category: selectedCategory!,
                                reason: reasonCtrl.text.trim(),
                              );
                          if (context.mounted) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      user.photoUrls.isNotEmpty
                          ? CachedNetworkImage(imageUrl: user.photoUrls.first, fit: BoxFit.cover)
                          : Container(
                              color: AppColors.terracottaSoft,
                              child: Center(child: Text(
                                user.name.isNotEmpty ? user.name[0] : '?',
                                style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.terracotta),
                              )),
                            ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Material(
                          color: Colors.transparent,
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.more_vert, color: Colors.white, size: 16),
                            ),
                            onSelected: (value) {
                              if (value == 'block') _blockUser(context, ref, user.firstName);
                              if (value == 'report') _reportUser(context, ref, user.firstName);
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
                        ),
                      ),
                    ],
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
