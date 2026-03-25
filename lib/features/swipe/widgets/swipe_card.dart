import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../services/matching_service.dart' show MatchingService, tagsFromQuestionnaire;

class SwipeCard extends StatefulWidget {
  final UserModel user;
  final UserModel? currentUser;
  final bool isTop;
  final VoidCallback? onLike;
  final VoidCallback? onPass;

  const SwipeCard({
    super.key,
    required this.user,
    this.currentUser,
    this.isTop = false,
    this.onLike,
    this.onPass,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> {
  int _currentPhotoIndex = 0;

  int get _compatibility {
    final a = widget.currentUser?.questionnaire;
    final b = widget.user.questionnaire;
    if (a == null || b == null) return 0;
    return MatchingService.calculateCompatibility(a, b);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) {
        final width = context.size?.width ?? 300;
        if (details.localPosition.dx > width / 2) {
          setState(() {
            if (_currentPhotoIndex < widget.user.photoUrls.length - 1)
              _currentPhotoIndex++;
          });
        } else {
          setState(() {
            if (_currentPhotoIndex > 0) _currentPhotoIndex--;
          });
        }
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Photo section
            SizedBox(
              height: 380,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildPhoto(),
                  if (widget.user.photoUrls.length > 1)
                    Positioned(
                        top: 12, left: 12, right: 12, child: _buildPhotoDots()),
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppColors.navy.withValues(alpha: 0.9),
                            Colors.transparent
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Compatibility badge
                  if (_compatibility > 0)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('✨', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              '$_compatibility% match',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.terracotta),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Name/info overlay
                  Positioned(
                    bottom: 20,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.user.name}, ${widget.user.age}',
                          style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.user.major} · ${widget.user.university}',
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.9)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.user.bio.isNotEmpty) ...[
                    Text(
                      widget.user.bio,
                      style: GoogleFonts.inter(
                          fontSize: 15, color: AppColors.textSoft, height: 1.6),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Tags
                  if (widget.user.questionnaire != null)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tagsFromQuestionnaire(widget.user.questionnaire!, maxTags: 4)
                          .map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(tag,
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.textSoft)),
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: 20),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onPass,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSoft,
                            side: const BorderSide(
                                color: AppColors.border, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Pass',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.onLike,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.terracotta,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Connect 💜',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    if (widget.user.photoUrls.isEmpty) {
      return Container(
        color: AppColors.terracottaSoft,
        child: Center(
          child: Text(
            widget.user.name.isNotEmpty
                ? widget.user.name[0].toUpperCase()
                : '?',
            style: GoogleFonts.inter(
                fontSize: 80,
                fontWeight: FontWeight.w800,
                color: AppColors.terracotta),
          ),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: widget.user.photoUrls[_currentPhotoIndex],
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
          color: AppColors.creamLight,
          child: const Center(
              child: CircularProgressIndicator(color: AppColors.terracotta))),
      errorWidget: (_, __, ___) => Container(
          color: AppColors.creamLight,
          child:
              const Icon(Icons.person, size: 80, color: AppColors.textLight)),
    );
  }

  Widget _buildPhotoDots() {
    return Row(
      children: List.generate(
          widget.user.photoUrls.length,
          (i) => Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: i == _currentPhotoIndex
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              )),
    );
  }
}
