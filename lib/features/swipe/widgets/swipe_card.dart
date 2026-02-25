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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo
              _buildPhoto(),

              // Photo indicator dots
              if (widget.user.photoUrls.length > 1)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: _buildPhotoDots(),
                ),

              // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 220,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
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
        color: AppColors.primaryBlue.withValues(alpha: 0.15),
        child: Center(
          child: Text(
            widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?',
            style: const TextStyle(
              fontSize: 96,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
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
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
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
    final color = score >= 75
        ? AppColors.like
        : score >= 50
            ? Colors.orange
            : AppColors.pass;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            '\$score%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  widget.user.age.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.school_outlined, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '\${widget.user.major} • \${widget.user.university}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (widget.user.bio.isNotEmpty) ...[
            const SizedBox(height: 6),
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
            Text(
              MatchingService.compatibilityLabel(compat),
              style: TextStyle(
                color: compat >= 75 ? AppColors.like : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
