import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../services/matching_service.dart' show MatchingService, tagsFromQuestionnaire;
import '../../../shared/widgets/glass_container.dart';

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

  Color get _compatColor {
    if (_compatibility >= 80) return AppColors.success;
    if (_compatibility >= 60) return AppColors.terracotta;
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final tags = widget.user.questionnaire != null
        ? tagsFromQuestionnaire(widget.user.questionnaire!, maxTags: 3)
        : <String>[];

    return GestureDetector(
      onTapUp: (details) {
        final width = context.size?.width ?? 300;
        if (details.localPosition.dx > width / 2) {
          setState(() {
            if (_currentPhotoIndex < widget.user.photoUrls.length - 1) {
              _currentPhotoIndex++;
            }
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
          borderRadius: BorderRadius.circular(28),
          color: AppColors.navy,
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.35),
              blurRadius: 50,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: 0.72,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Full-bleed photo
              _buildPhoto(),

              // Photo cycle dots at top
              if (widget.user.photoUrls.length > 1)
                Positioned(top: 14, left: 14, right: 14, child: _buildPhotoDots()),

              // Dark gradient bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 360,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.55, 1.0],
                      colors: [
                        AppColors.navyDeep,
                        AppColors.navy.withValues(alpha: 0.75),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Match % glass badge — top right
              if (_compatibility > 0)
                Positioned(
                  top: 36,
                  right: 16,
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    borderRadius: BorderRadius.circular(999),
                    fill: Colors.white.withValues(alpha: 0.85),
                    shadows: [
                      BoxShadow(
                        color: _compatColor.withValues(alpha: 0.45),
                        blurRadius: 22,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _compatColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _compatColor.withValues(alpha: 0.6),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(begin: const Offset(0.85, 0.85), end: const Offset(1.15, 1.15), duration: 900.ms),
                        const SizedBox(width: 8),
                        Text(
                          '$_compatibility%',
                          style: AppTheme.displayStyle(
                            fontSize: 18,
                            color: AppColors.navy,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'match',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Bottom info stack
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Vibe tags floating above name
                      if (tags.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: tags
                              .map((t) => GlassContainer(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    borderRadius: BorderRadius.circular(999),
                                    fill: Colors.white.withValues(alpha: 0.18),
                                    stroke: Colors.white.withValues(alpha: 0.35),
                                    child: Text(
                                      t,
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      const SizedBox(height: 12),

                      // Name in display font, age tucked in
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              widget.user.name,
                              style: AppTheme.displayStyle(
                                fontSize: 36,
                                color: Colors.white,
                                letterSpacing: -1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '${widget.user.age}',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.school_rounded,
                              size: 14, color: Colors.white.withValues(alpha: 0.75)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${widget.user.major} · ${widget.user.university}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (widget.user.bio.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          widget.user.bio,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: Colors.white.withValues(alpha: 0.92),
                            height: 1.5,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 18),

                      // Action row — circular floating buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _CircleAction(
                            icon: Icons.close_rounded,
                            color: Colors.white,
                            bg: Colors.white.withValues(alpha: 0.14),
                            border: Colors.white.withValues(alpha: 0.35),
                            size: 56,
                            onTap: widget.onPass,
                          ),
                          _CircleAction(
                            icon: Icons.favorite_rounded,
                            color: Colors.white,
                            gradient: AppColors.primaryGradient,
                            size: 68,
                            glow: AppColors.terracotta,
                            onTap: widget.onLike,
                          ),
                          _CircleAction(
                            icon: Icons.bolt_rounded,
                            color: AppColors.superLike,
                            bg: Colors.white,
                            size: 56,
                            glow: AppColors.superLike,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    if (widget.user.photoUrls.isEmpty) {
      return Container(
        decoration: const BoxDecoration(gradient: AppColors.navyGradient),
        child: Center(
          child: Text(
            widget.user.name.isNotEmpty
                ? widget.user.name[0].toUpperCase()
                : '?',
            style: AppTheme.displayStyle(
              fontSize: 140,
              color: AppColors.terracotta,
              letterSpacing: -4,
            ),
          ),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: widget.user.photoUrls[_currentPhotoIndex],
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
          color: AppColors.navyDeep,
          child: const Center(
              child: CircularProgressIndicator(color: AppColors.terracotta))),
      errorWidget: (_, __, ___) => Container(
          color: AppColors.navyDeep,
          child:
              const Icon(Icons.person, size: 80, color: AppColors.textLight)),
    );
  }

  Widget _buildPhotoDots() {
    return Row(
      children: List.generate(
          widget.user.photoUrls.length,
          (i) => Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: i == _currentPhotoIndex
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.35),
                    boxShadow: i == _currentPhotoIndex
                        ? [
                            BoxShadow(
                                color: Colors.white.withValues(alpha: 0.6),
                                blurRadius: 6),
                          ]
                        : null,
                  ),
                ),
              )),
    );
  }
}

class _CircleAction extends StatefulWidget {
  final IconData icon;
  final Color color;
  final Color? bg;
  final Color? border;
  final Color? glow;
  final LinearGradient? gradient;
  final double size;
  final VoidCallback? onTap;

  const _CircleAction({
    required this.icon,
    required this.color,
    required this.size,
    this.bg,
    this.border,
    this.glow,
    this.gradient,
    this.onTap,
  });

  @override
  State<_CircleAction> createState() => _CircleActionState();
}

class _CircleActionState extends State<_CircleAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: widget.gradient,
            color: widget.gradient == null ? widget.bg : null,
            border: widget.border != null
                ? Border.all(color: widget.border!, width: 1.5)
                : null,
            boxShadow: widget.glow != null
                ? [
                    BoxShadow(
                      color: widget.glow!.withValues(alpha: _pressed ? 0.25 : 0.5),
                      blurRadius: _pressed ? 14 : 26,
                      offset: const Offset(0, 8),
                      spreadRadius: _pressed ? -2 : 0,
                    ),
                  ]
                : null,
          ),
          child: Icon(widget.icon, color: widget.color, size: widget.size * 0.45),
        ),
      ),
    );
  }
}
