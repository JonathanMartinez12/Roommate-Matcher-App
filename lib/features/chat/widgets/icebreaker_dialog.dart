import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../services/icebreaker_service.dart';

/// Modal bottom sheet that surfaces a handcrafted icebreaker question
/// for the conversation between [me] and [other]. The user can:
///   • Send the question as-is
///   • Tweak the wording in an inline text field, then send
///   • Regenerate to get a new suggestion
///   • Dismiss without sending
///
/// On send, the resolved text is returned via [Navigator.pop]; on cancel
/// the sheet pops with `null`.
class IcebreakerDialog extends StatefulWidget {
  final UserModel me;
  final UserModel? other;

  const IcebreakerDialog({
    super.key,
    required this.me,
    required this.other,
  });

  /// Convenience launcher — returns the message the user committed to
  /// sending, or `null` if they backed out.
  static Future<String?> show(
    BuildContext context, {
    required UserModel me,
    required UserModel? other,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IcebreakerDialog(me: me, other: other),
    );
  }

  @override
  State<IcebreakerDialog> createState() => _IcebreakerDialogState();
}

class _IcebreakerDialogState extends State<IcebreakerDialog> {
  final _service = IcebreakerService();
  final _controller = TextEditingController();
  final _seen = <String>{};

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    final next = _service.generate(
      widget.me,
      widget.other,
      exclude: _seen,
    );
    _seen.add(next);
    _controller.text = next;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.terracottaSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.terracotta,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Icebreaker suggestion',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        'Tweak it, send it, or generate a new one.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight, width: 2),
                color: AppColors.surfaceAlt,
              ),
              child: TextField(
                controller: _controller,
                maxLines: 5,
                minLines: 3,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.text,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: 'Your icebreaker will appear here...',
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _SecondaryButton(
                  icon: Icons.refresh_rounded,
                  label: 'New idea',
                  onTap: () => setState(_generate),
                ),
                const SizedBox(width: 10),
                _SecondaryButton(
                  icon: Icons.close_rounded,
                  label: 'Cancel',
                  onTap: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _send,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    'Send',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.textSoft),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
