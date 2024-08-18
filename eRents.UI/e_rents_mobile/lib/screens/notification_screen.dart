// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:e_rents_mobile/providers/notification_provider.dart';

// class NotificationsScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => NotificationProvider()..fetchNotifications(),
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text('Notifications'),
//         ),
//         body: Consumer<NotificationProvider>(
//           builder: (context, provider, child) {
//             if (provider.isLoading) {
//               return Center(child: CircularProgressIndicator());
//             } else if (provider.errorMessage != null) {
//               return Center(child: Text('Error: ${provider.errorMessage}'));
//             } else if (provider.notifications.isEmpty) {
//               return Center(child: Text('No notifications available.'));
//             } else {
//               return ListView.builder(
//                 itemCount: provider.notifications.length,
//                 itemBuilder: (context, index) {
//                   final notification = provider.notifications[index];
//                   return ListTile(
//                     title: Text(notification.message),
//                     subtitle: Text(notification.date.toString()),
//                   );
//                 },
//               );
//             }
//           },
//         ),
//       ),
//     );
//   }
// }
