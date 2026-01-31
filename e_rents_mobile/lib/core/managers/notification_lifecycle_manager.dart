import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:e_rents_mobile/features/notifications/providers/notification_provider.dart';

/// Global manager for notification lifecycle - establishes SignalR connection
/// immediately after login and maintains it throughout app lifecycle.
class NotificationLifecycleManager with WidgetsBindingObserver {
  final NotificationProvider _notificationProvider;
  Timer? _reconnectionTimer;
  bool _shouldBeConnected = false;
  bool _isInitialized = false;

  NotificationLifecycleManager(this._notificationProvider);

  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> onAuthenticated() async {
    _shouldBeConnected = true;
    await _connect();
  }

  Future<void> onLoggedOut() async {
    _shouldBeConnected = false;
    await _disconnect();
  }

  Future<void> _connect() async {
    if (!_shouldBeConnected) return;
    try {
      await _notificationProvider.connectRealtime();
      _startReconnectionMonitor();
      debugPrint('NotificationLifecycleManager: SignalR connected');
    } catch (e) {
      debugPrint('NotificationLifecycleManager: Failed to connect: $e');
    }
  }

  Future<void> _disconnect() async {
    _stopReconnectionMonitor();
    try {
      await _notificationProvider.disconnectRealtime();
      debugPrint('NotificationLifecycleManager: SignalR disconnected');
    } catch (e) {
      debugPrint('NotificationLifecycleManager: Error disconnecting: $e');
    }
  }

  void _startReconnectionMonitor() {
    _stopReconnectionMonitor();
    _reconnectionTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_shouldBeConnected && !_notificationProvider.isRealtimeConnected) {
        debugPrint('NotificationLifecycleManager: Reconnecting...');
        _connect();
      }
    });
  }

  void _stopReconnectionMonitor() {
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _shouldBeConnected && !_notificationProvider.isRealtimeConnected) {
      _connect();
    }
  }

  void dispose() {
    _stopReconnectionMonitor();
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
  }
}
