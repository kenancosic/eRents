import 'package:e_rents_mobile/features/chat/backend_chat_provider.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/widgets/custom_avatar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ConversationScreen extends StatefulWidget {
  final int contactId;
  final String contactName;

  const ConversationScreen({super.key, required this.contactId, required this.contactName});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _loadingMore = false;
  int _lastRenderedCount = 0;

  Future<void> _scrollToBottom() async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.maxScrollExtent > 0) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final provider = context.read<BackendChatProvider>();
      await provider.loadMessages(widget.contactId, refresh: true);
      await provider.connectRealtime();
      // scroll to bottom after first load
      _scrollToBottom();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() async {
    if (_scrollController.position.pixels <= 100 && !_loadingMore) {
      // near top -> load older
      final chat = context.read<BackendChatProvider>();
      if (chat.hasMore(widget.contactId)) {
        setState(() => _loadingMore = true);
        await chat.loadMessages(widget.contactId);
        setState(() => _loadingMore = false);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    
    // Unfocus to dismiss keyboard
    FocusScope.of(context).unfocus();
    
    // Add a minimal delay to ensure UI updates
    await Future.delayed(const Duration(milliseconds: 10));
    
    await context.read<BackendChatProvider>().sendMessageRealtime(widget.contactId, text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<BackendChatProvider>();
    final api = context.read<ApiService>();
    // Find matching contact if available
    var contact = chat.contacts.where((u) => (u.userId ?? 0) == widget.contactId);
    final hasContact = contact.isNotEmpty;
    final avatarUrl = hasContact && (contact.first.profileImageId != null) && (contact.first.profileImageId! > 0)
        ? api.makeAbsoluteUrl('/api/Images/${contact.first.profileImageId}/content')
        : 'assets/images/user-image.png';
    final displayName = widget.contactName;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: GestureDetector(
          onTap: () {
            context.push('/user/${widget.contactId.toString()}', extra: {
              'displayName': displayName,
            });
          },
          child: Row(
            children: [
              CustomAvatar(imageUrl: avatarUrl, size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<BackendChatProvider>(
              builder: (context, chat, _) {
                final messages = chat.messagesFor(widget.contactId);
                if (chat.isLoading && messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Auto-scroll when new messages arrive
                if (messages.length != _lastRenderedCount) {
                  _lastRenderedCount = messages.length;
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                }
                return ListView.builder(
                  controller: _scrollController,
                  // Keep natural order (oldest at top), new messages appended at end
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    // In 1:1 chat, any message whose senderId equals the contactId is theirs; others are mine.
                    final isMe = m.senderId != widget.contactId;
                    final time = DateFormat('HH:mm').format(m.dateSent ?? DateTime.now());
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? Theme.of(context).primaryColor : Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.messageText,
                                    style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _send,
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
