import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/profile/profile_screen.dart';
import 'package:e_rents_desktop/features/profile/providers/profile_provider.dart';
import 'package:e_rents_desktop/services/profile_service.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';
import 'package:e_rents_desktop/models/user.dart';

void main() {
  group('Profile Feature Integration Tests', () {
    late ProfileService profileService;
    late ProfileProvider profileProvider;

    setUp(() {
      // Create mock services
      final secureStorageService = SecureStorageService();
      profileService = ProfileService(
        'http://localhost:5000',
        secureStorageService,
      );
      profileProvider = ProfileProvider(profileService);

      // Enable mock data for testing
      profileProvider.enableMockData();
    });

    testWidgets('ProfileScreen renders without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider.value(value: profileService),
              ChangeNotifierProvider.value(value: profileProvider),
            ],
            child: const ProfileScreen(),
          ),
        ),
      );

      // Allow the widget to build and handle async operations
      await tester.pump();

      // Verify the profile screen renders
      expect(find.byType(ProfileScreen), findsOneWidget);

      // Verify loading indicator shows initially (since no mock user is set)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('ProfileScreen shows error when no user data', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider.value(value: profileService),
              ChangeNotifierProvider.value(value: profileProvider),
            ],
            child: const ProfileScreen(),
          ),
        ),
      );

      // Allow async operations to complete
      await tester.pumpAndSettle();

      // Since ProfileProvider.getMockItems() returns empty list,
      // and fetchUserProfile will likely result in an error state,
      // we should see an error indicator or retry button
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    test('ProfileService initializes correctly', () {
      expect(profileService, isNotNull);
      expect(profileService, isA<ProfileService>());
    });

    test('ProfileProvider initializes correctly', () {
      expect(profileProvider, isNotNull);
      expect(profileProvider, isA<ProfileProvider>());
      expect(profileProvider.currentUser, isNull);
    });

    test('ProfileProvider mock data works', () async {
      profileProvider.enableMockData();

      // Mock data should be empty initially for profile
      expect(profileProvider.getMockItems(), isEmpty);

      // But the provider should handle the mock state correctly
      expect(profileProvider.isMockDataEnabled, isTrue);
    });
  });

  group('Profile Models Integration', () {
    test('User model serialization works correctly', () {
      final user = User(
        id: 1,
        email: 'test@example.com',
        username: 'testuser',
        firstName: 'Test',
        lastName: 'User',
        phone: '+1234567890',
        role: UserType.landlord,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPaypalLinked: true,
        paypalUserIdentifier: 'test@paypal.com',
      );

      // Test serialization
      final json = user.toJson();
      expect(json['userId'], equals(1));
      expect(json['email'], equals('test@example.com'));
      expect(json['firstName'], equals('Test'));
      expect(json['lastName'], equals('User'));
      expect(json['phoneNumber'], equals('+1234567890'));
      expect(json['isPaypalLinked'], equals(true));
      expect(json['paypalUserIdentifier'], equals('test@paypal.com'));

      // Test deserialization
      final deserializedUser = User.fromJson(json);
      expect(deserializedUser.id, equals(user.id));
      expect(deserializedUser.email, equals(user.email));
      expect(deserializedUser.firstName, equals(user.firstName));
      expect(deserializedUser.lastName, equals(user.lastName));
      expect(deserializedUser.phone, equals(user.phone));
      expect(deserializedUser.isPaypalLinked, equals(user.isPaypalLinked));
      expect(
        deserializedUser.paypalUserIdentifier,
        equals(user.paypalUserIdentifier),
      );
    });

    test('User copyWith method works correctly', () {
      final user = User(
        id: 1,
        email: 'test@example.com',
        username: 'testuser',
        firstName: 'Test',
        lastName: 'User',
        role: UserType.landlord,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updatedUser = user.copyWith(
        firstName: 'Updated',
        phone: '+9876543210',
        isPaypalLinked: true,
      );

      expect(updatedUser.firstName, equals('Updated'));
      expect(updatedUser.phone, equals('+9876543210'));
      expect(updatedUser.isPaypalLinked, equals(true));

      // Other fields should remain the same
      expect(updatedUser.id, equals(user.id));
      expect(updatedUser.email, equals(user.email));
      expect(updatedUser.lastName, equals(user.lastName));
    });
  });

  group('Profile Provider State Management', () {
    late ProfileProvider provider;

    setUp(() {
      final secureStorageService = SecureStorageService();
      final profileService = ProfileService(
        'http://localhost:5000',
        secureStorageService,
      );
      provider = ProfileProvider(profileService);
    });

    test('Provider starts with null user', () {
      expect(provider.currentUser, isNull);
    });

    test('Provider can update user personal info', () {
      // The method should work without throwing errors
      expect(
        () => provider.updateUserPersonalInfo('Test', 'User', '+1234567890'),
        returnsNormally,
      );
    });

    test('Provider handles mock data state correctly', () {
      expect(provider.isMockDataEnabled, isFalse);

      provider.enableMockData();
      expect(provider.isMockDataEnabled, isTrue);

      provider.disableMockData();
      expect(provider.isMockDataEnabled, isFalse);
    });
  });
}
