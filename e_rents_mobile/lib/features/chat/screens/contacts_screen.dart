import 'package:e_rents_mobile/features/chat/backend_chat_provider.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/widgets/custom_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final provider = context.read<BackendChatProvider>();
      await provider.loadContacts();
      // Ensure SignalR presence updates begin
      await provider.connectRealtime();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: Consumer<BackendChatProvider>(
        builder: (context, chat, _) {
          final contacts = chat.contacts;
          if (chat.isLoading && contacts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (contacts.isEmpty) {
            return const Center(child: Text('No contacts yet'));
          }
          final api = context.read<ApiService>();
          return RefreshIndicator(
            onRefresh: chat.loadContacts,
            child: ListView.separated(
              itemCount: contacts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final u = contacts[index];
                final userId = u.userId ?? 0;
                final isOnline = chat.isOnline(userId);
                final displayName = (u.fullName.isNotEmpty ? u.fullName : (u.username.isNotEmpty ? u.username : (userId > 0 ? 'User #$userId' : 'Unknown User')));
                final subtitleText = (u.email.isNotEmpty ? u.email : (u.username.isNotEmpty ? '@${u.username}' : ''));
                final avatarUrl = (u.profileImageId != null && u.profileImageId! > 0)
                    ? api.makeAbsoluteUrl('/api/Images/${u.profileImageId}/content')
                    : 'assets/images/user-image.png';
                return ListTile(
                  leading: Stack(
                    children: [
                      CustomAvatar(
                        imageUrl: avatarUrl,
                        size: 40,
                        onTap: () {
                          if (userId > 0) {
                            context.push('/user/${userId.toString()}', extra: {
                              'displayName': displayName,
                            });
                          }
                        },
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isOnline ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: subtitleText.isEmpty
                      ? null
                      : Text(
                          subtitleText,
                          style: const TextStyle(color: Colors.black54),
                        ),
                  onTap: () {
                    context.push('/chat/${userId.toString()}', extra: {
                      'name': displayName,
                    });
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
