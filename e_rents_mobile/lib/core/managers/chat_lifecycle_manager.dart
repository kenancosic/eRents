import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:e_rents_mobile/features/chat/backend_chat_provider.dart';

/// Global manager for chat lifecycle - establishes SignalR connection
/// immediately after login and maintains it throughout app lifecycle.
/// 
/// This ensures real-time message delivery works regardless of which
/// screen the user is viewing.
class ChatLifecycleManager with WidgetsBindingObserver {
  final BackendChatProvider _chatProvider;
  Timer? _reconnectionTimer;
  bool _shouldBeConnected = false;
  bool _isInitialized = false;

  ChatLifecycleManager(this._chatProvider);

  /// Initialize the lifecycle manager and register as observer
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
  }

  /// Call when user successfully authenticates
  Future<void> onAuthenticated() async {
    _shouldBeConnected = true;
    await _connect();
  }

  /// Call when user logs out
  Future<void> onLoggedOut() async {
    _shouldBeConnected = false;
    await _disconnect();
  }

  /// Attempt to establish SignalR connection
  Future<void> _connect() async {
    if (!_shouldBeConnected) return;
    
    try {
      await _chatProvider.connectRealtime();
      _startReconnectionMonitor();
      debugPrint('ChatLifecycleManager: SignalR connected successfully');
    } catch (e) {
      debugPrint('ChatLifecycleManager: Failed to connect SignalR: $e');
      // Will retry via reconnection monitor
    }
  }

  /// Disconnect SignalR and stop monitoring
  Future<void> _disconnect() async {
    _stopReconnectionMonitor();
    try {
      await _chatProvider.disconnectRealtime();
      debugPrint('ChatLifecycleManager: SignalR disconnected');
    } catch (e) {
      debugPrint('ChatLifecycleManager: Error disconnecting SignalR: $e');
    }
  }

  /// Start periodic check for connection health
  void _startReconnectionMonitor() {
    _stopReconnectionMonitor();
    _reconnectionTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_shouldBeConnected && !_chatProvider.isRealtimeConnected) {
        debugPrint('ChatLifecycleManager: Connection lost, attempting reconnect...');
        _connect();
      }
    });
  }

  /// Stop the reconnection monitor timer
  void _stopReconnectionMonitor() {
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - verify connection
        if (_shouldBeConnected && !_chatProvider.isRealtimeConnected) {
          debugPrint('ChatLifecycleManager: App resumed, reconnecting...');
          _connect();
        }
        break;
      case AppLifecycleState.paused:
        // App went to background - keep connection for push notifications
        debugPrint('ChatLifecycleManager: App paused, maintaining connection');
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        debugPrint('ChatLifecycleManager: App detached, disconnecting');
        _disconnect();
        break;
      case AppLifecycleState.inactive:
        // Transitional state - do nothing
        break;
      case AppLifecycleState.hidden:
        // App is hidden but still running
        break;
    }
  }

  /// Clean up resources
  void dispose() {
    _stopReconnectionMonitor();
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
  }
}
