import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../routes/base_screen.dart';

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Notifications',
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          return ListView.builder(
            itemCount: provider.notifications.length,
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              return ListTile(
                title: Text(notification.title),
                subtitle: Text(notification.message),
                trailing: notification.isRead
                    ? Icon(Icons.check, color: Colors.green)
                    : Icon(Icons.new_releases, color: Colors.red),
                onTap: () {
                  provider.markAsRead(notification.id);
                },
              );
            },
          );
        },
      ),
    );
  }
}
