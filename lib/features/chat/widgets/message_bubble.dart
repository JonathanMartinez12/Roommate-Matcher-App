import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showTime;

  const MessageBubble({super.key, required this.message, required this.isMe, this.showTime = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) const SizedBox(width: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.navy : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 20),
                  ),
                  boxShadow: isMe ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      message.text,
                      style: GoogleFonts.inter(color: isMe ? Colors.white : AppColors.text, fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('h:mm a').format(message.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isMe ? Colors.white.withValues(alpha: 0.6) : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isMe) const SizedBox(width: 8),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
