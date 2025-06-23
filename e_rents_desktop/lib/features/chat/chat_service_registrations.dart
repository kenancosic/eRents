import 'package:e_rents_desktop/base/service_locator.dart';
import 'package:e_rents_desktop/services/chat_service.dart';
import 'package:e_rents_desktop/repositories/chat_repository.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';
import 'package:e_rents_desktop/base/cache_manager.dart';

/// Helper class to register all chat-related services with the service locator
class ChatServiceRegistrations {
  /// Register all chat-related services
  static void registerServices(ServiceLocator locator, String baseUrl) {
    locator.registerLazySingleton<ChatService>(
      () => ChatService(baseUrl, locator.get<SecureStorageService>()),
    );

    locator.registerLazySingleton<ChatRepository>(
      () => ChatRepository(
        apiService: locator.get<ChatService>(),
        service: locator.get<ChatService>(),
        cacheManager: locator.get<CacheManager>(),
      ),
    );
  }
}
