import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../services/matching_service.dart';

class SwipeCard extends StatefulWidget {
  final UserModel user;
  final UserModel? currentUser;
  final bool isTop;

  const SwipeCard({
    super.key,
    required this.user,
    this.currentUser,
    this.isTop = false,
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo
              _buildPhoto(),

              // Photo indicator bars
              if (widget.user.photoUrls.length > 1)
                Positioned(
                  top: 14,
                  left: 14,
                  right: 14,
                  child: _buildPhotoDots(),
                ),

              // Bottom gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 240,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.88),
                        Colors.transparent,
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
                  child: _buildCompatibilityBadge(),
                ),

              // User info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildUserInfo(),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.2),
              AppColors.secondary.withValues(alpha: 0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?',
            style: const TextStyle(
              fontSize: 96,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    final url = widget.user.photoUrls[_currentPhotoIndex];
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (_, __, ___) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.person, size: 80, color: Colors.grey),
      ),
    );
  }

  Widget _buildPhotoDots() {
    return Row(
      children: List.generate(widget.user.photoUrls.length, (i) {
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: i == _currentPhotoIndex
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCompatibilityBadge() {
    final score = _compatibility;
    final Color badgeColor;
    if (score >= 75) {
      badgeColor = AppColors.like;
    } else if (score >= 50) {
      badgeColor = AppColors.highlight;
    } else {
      badgeColor = AppColors.pass;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt, color: Colors.white, size: 14),
          const SizedBox(width: 3),
          Text(
            '$score%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    final compat = _compatibility;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  widget.user.age.toString(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.school_outlined, color: Colors.white70, size: 14),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  '${widget.user.major} · ${widget.user.university}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (widget.user.bio.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              widget.user.bio,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (compat > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                MatchingService.compatibilityLabel(compat),
                style: TextStyle(
                  color: compat >= 75 ? AppColors.like : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
