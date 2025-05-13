import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:e_rents_desktop/models/message.dart';
import 'package:e_rents_desktop/features/chat/widgets/property_offer_card_widget.dart';

class ChatMessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onDelete; // Optional delete callback for 'my' messages

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onDelete,
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

    // Check if the message is a property offer
    if (message.messageText.startsWith("PROPERTY_OFFER::")) {
      final propertyId = message.messageText.split("::").last;
      messageContent = PropertyOfferCardWidget(propertyId: propertyId);
    } else {
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
    }

    // Add delete button conditionally
    if (isMe && onDelete != null) {
      messageContent = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Delete button appears before the bubble for 'my' messages
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: Colors.grey[600]),
            onPressed: onDelete,
            tooltip: 'Delete message',
            padding: const EdgeInsets.only(right: 4),
            constraints: const BoxConstraints(),
          ),
          messageContent,
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          if (message.isDeleted)
            Text(
              'Message deleted',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey[500],
                fontSize: 13,
              ),
            )
          else
            messageContent,
        ],
      ),
    );
  }
}
