import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/message_provider.dart';
import '../../models/message.dart';
import '../../routes/base_screen.dart';

class MessageScreen extends StatelessWidget {
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Messages',
      body: Column(
        children: <Widget>[
          Expanded(
            child: Consumer<MessageProvider>(
              builder: (context, provider, child) {
                return ListView.builder(
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final message = provider.messages[index];
                    return ListTile(
                      title: Text(message.messageText),
                      subtitle: Text('From: ${message.senderId}'),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(labelText: 'Type a message'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    final newMessage = Message(
                      messageId: DateTime.now().millisecondsSinceEpoch,
                      senderId: 1, // Example sender ID, should be dynamic
                      receiverId: 2, // Example receiver ID, should be dynamic
                      messageText: _messageController.text,
                      dateSent: DateTime.now(),
                    );
                    Provider.of<MessageProvider>(context, listen: false).sendMessage(newMessage);
                    _messageController.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
