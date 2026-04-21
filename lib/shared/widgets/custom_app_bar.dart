import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class RoomrAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool useGradientTitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showLogo;

  const RoomrAppBar({
    super.key,
    required this.title,
    this.useGradientTitle = false,
    this.actions,
    this.leading,
    this.showLogo = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.navy,
      elevation: 0,
      leading: leading,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLogo) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: AppColors.terracotta, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.home_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.03 * 22,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}
