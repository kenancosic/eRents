import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String messageText;
  final bool isSentByMe;

  const MessageBubble({
    Key? key,
    required this.messageText,
    required this.isSentByMe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
        padding: EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: isSentByMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Text(
          messageText,
          style: TextStyle(
            color: isSentByMe ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
