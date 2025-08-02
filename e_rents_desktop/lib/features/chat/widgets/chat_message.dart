import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:e_rents_desktop/models/message.dart';

class ChatMessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isMe ? theme.colorScheme.primary : Colors.grey[200];
    final textColor = isMe ? Colors.white : Colors.black87;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
      bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
    );

    Widget messageContent;

    messageContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.65,
      ),
      decoration: BoxDecoration(color: color, borderRadius: borderRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.messageText,
            style: TextStyle(color: textColor, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat(
              'HH:mm',
            ).format(message.dateSent), // Simple time format
            style: TextStyle(
              color: isMe ? Colors.white70 : Colors.black54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          messageContent,
        ],
      ),
    );
  }
}
