import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../services/matching_service.dart';

class MatchPopup extends StatefulWidget {
  final UserModel currentUser;
  final UserModel matchedUser;
  final String matchId;
  final VoidCallback onDismiss;

  const MatchPopup({
    super.key,
    required this.currentUser,
    required this.matchedUser,
    required this.matchId,
    required this.onDismiss,
  });

  @override
  State<MatchPopup> createState() => _MatchPopupState();
}

class _MatchPopupState extends State<MatchPopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  int get _compatibility {
    final a = widget.currentUser.questionnaire;
    final b = widget.matchedUser.questionnaire;
    if (a == null || b == null) return 85;
    return MatchingService.calculateCompatibility(a, b);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          color: AppColors.navy.withValues(alpha: 0.9),
          child: BackdropFilter(
            filter: const ColorFilter.mode(Colors.transparent, BlendMode.src),
            child: Center(
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 420,
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.celebration_outlined, size: 60, color: AppColors.terracotta),
                      const SizedBox(height: 20),
                      Text(
                        "It's a match!",
                        style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.navy),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You and ${widget.matchedUser.name} both want to be roommates',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 16, color: AppColors.textSoft),
                      ),
                      const SizedBox(height: 28),
                      // Avatar
                      Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.terracotta, width: 4),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: widget.matchedUser.photoUrls.isNotEmpty
                            ? CachedNetworkImage(imageUrl: widget.matchedUser.photoUrls.first, fit: BoxFit.cover)
                            : Container(
                                color: AppColors.terracottaSoft,
                                child: Center(
                                  child: Text(
                                    widget.matchedUser.name.isNotEmpty ? widget.matchedUser.name[0] : '?',
                                    style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.terracotta),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.terracottaSoft,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          '$_compatibility% compatible',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.terracotta),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onDismiss();
                            context.push(
                              '/chat/${widget.matchId}?name=${Uri.encodeComponent(widget.matchedUser.name)}&photo=${Uri.encodeComponent(widget.matchedUser.photoUrls.isNotEmpty ? widget.matchedUser.photoUrls.first : "")}&userId=${widget.matchedUser.id}',
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.terracotta,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Send a message', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: widget.onDismiss,
                        child: Text('Keep browsing', style: GoogleFonts.inter(fontSize: 15, color: AppColors.textMuted)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
