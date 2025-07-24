import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/models/message.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/paged_result.dart';

class ChatProviderRefactored extends BaseProvider {
  ChatProviderRefactored(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  List<User> _contacts = [];
  List<User> get contacts => _contacts;

  int? _selectedContactId;
  int? get selectedContactId => _selectedContactId;

  final Map<int, List<Message>> _conversations = {};
  final Map<int, int> _currentPage = {};
  final Map<int, bool> _hasMoreMessages = {};
  static const int _pageSize = 50;

  // ─── Getters ────────────────────────────────────────────────────────────
  bool get isLoadingContacts => isLoading;
  bool get isLoadingMessages => isLoading;

  User? get selectedContact => _selectedContactId == null
      ? null
      : _contacts.cast<User?>().firstWhere((c) => c?.id == _selectedContactId, orElse: () => null);

  List<Message> get activeConversationMessages => _conversations[_selectedContactId] ?? [];
  bool get hasMoreActiveConversationMessages => _hasMoreMessages[_selectedContactId] ?? true;

  // ─── Public API ─────────────────────────────────────────────────────────

  void selectContact(int? contactId) {
    if (_selectedContactId == contactId) return;
    _selectedContactId = contactId;

    if (contactId != null && (_conversations[contactId] == null || _conversations[contactId]!.isEmpty)) {
      loadMessages(contactId);
    }
    notifyListeners();
  }

  Future<void> loadContacts({bool forceRefresh = false}) async {
    const cacheKey = 'contacts';
    
    if (forceRefresh) {
      invalidateCache(cacheKey);
    }
    
    final result = await executeWithCache<List<User>>(
      cacheKey,
      () => api.getListAndDecode('/Chat/Contacts', User.fromJson, authenticated: true),
    );
    
    if (result != null) {
      _contacts = result;
      notifyListeners();
    }
  }

  Future<void> loadMessages(int contactId, {bool forceRefresh = false}) async {
    if (isLoading && !forceRefresh) return;

    if (forceRefresh) {
      _conversations.remove(contactId);
      _currentPage.remove(contactId);
      _hasMoreMessages.remove(contactId);
    }

    final page = _currentPage[contactId] ?? 0;
    final endpoint = '/Chat/$contactId/Messages';
    final params = {'page': page + 1, 'pageSize': _pageSize};

    final result = await executeWithState<PagedResult<Message>>(() async {
      return await api.getPagedAndDecode('$endpoint${api.buildQueryString(params)}', Message.fromJson, authenticated: true);
    });

    if (result != null) {
      final newMessages = result.items;
      
      if (page == 0) {
        _conversations[contactId] = newMessages;
      } else {
        _conversations[contactId]?.insertAll(0, newMessages); // Prepend older messages
      }

      _hasMoreMessages[contactId] = newMessages.length == _pageSize;
      _currentPage[contactId] = page + 1;
      notifyListeners();
    }
  }

  Future<void> loadMoreMessages() async {
    if (_selectedContactId != null && hasMoreActiveConversationMessages) {
      await loadMessages(_selectedContactId!);
    }
  }

  Future<bool> sendMessage(int receiverId, String messageText) async {
    final result = await executeWithState<Message>(() async {
      return await api.postAndDecode(
        '/Chat/SendMessage',
        {'receiverId': receiverId, 'messageText': messageText},
        Message.fromJson,
        authenticated: true,
      );
    });
    
    if (result != null) {
      _conversations[receiverId]?.add(result);
      _updateContactActivity(receiverId);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> markMessageAsRead(int messageId, int contactId) async {
    final result = await executeWithState<Map<String, dynamic>>(() async {
      return await api.putAndDecode('/Chat/$messageId/read', {}, (json) => json, authenticated: true);
    });
    
    if (result != null) {
      final conversation = _conversations[contactId];
      if (conversation != null) {
        final messageIndex = conversation.indexWhere((m) => m.id == messageId);
        if (messageIndex != -1) {
          conversation[messageIndex] = conversation[messageIndex].copyWith(isRead: true);
        }
      }
      notifyListeners();
    }
  }

  void clearAllData() {
    _contacts.clear();
    _conversations.clear();
    _currentPage.clear();
    _hasMoreMessages.clear();
    _selectedContactId = null;
    invalidateCache('contacts');
    clearError();
    notifyListeners();
  }

  // ─── Private Helpers ────────────────────────────────────────────────────

  void _updateContactActivity(int contactId) {
    final index = _contacts.indexWhere((c) => c.id == contactId);
    if (index != -1) {
      final contact = _contacts.removeAt(index);
      _contacts.insert(0, contact);
    }
  }
}
