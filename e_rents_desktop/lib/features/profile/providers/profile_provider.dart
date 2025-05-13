import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';
import 'dart:convert';
import 'package:e_rents_desktop/widgets/inputs/google_address_input.dart';

class ProfileProvider extends BaseProvider<User> {
  final ApiService _apiService;
  User? _currentUser;
  String? _errorMessage;

  ProfileProvider(this._apiService) : super(_apiService) {
    enableMockData(); // Enable mock data by default
  }

  User? get currentUser => _currentUser;
  @override
  String? get errorMessage => _errorMessage;

  @override
  String get endpoint => '/profile';

  @override
  User fromJson(Map<String, dynamic> json) => User.fromJson(json);

  @override
  Map<String, dynamic> toJson(User item) => item.toJson();

  @override
  List<User> getMockItems() {
    // Use the existing mock data service
    // Ensure mock user has some address data if needed for testing
    final mockUser = MockDataService.getMockUsers().first;
    return [mockUser.copyWith(formattedAddress: '123 Mock Street, Mockville')];
  }

  /// Helper method to determine if we should use mock data
  bool _shouldUseMockData() {
    return state == ViewState.Idle && items.isEmpty;
  }

  Future<void> fetchUserProfile() async {
    await execute(() async {
      try {
        if (_shouldUseMockData()) {
          _currentUser = getMockItems().first;
        } else {
          final response = await _apiService.get('$endpoint/me');
          final responseData = json.decode(response.body);
          _currentUser = User.fromJson(responseData);
        }
        notifyListeners(); // Ensure listeners are notified after fetching
      } catch (e) {
        _errorMessage = e.toString();
        // Consider setting state to Error here if not already handled by execute
      }
    });
  }

  Future<bool> updateProfile(User user) async {
    bool success = false;
    await execute(() async {
      try {
        if (_shouldUseMockData()) {
          _currentUser = user;
          success = true;
        } else {
          final response = await _apiService.put('$endpoint/me', user.toJson());
          final responseData = json.decode(response.body);
          _currentUser = User.fromJson(responseData);
          success = true;
        }
      } catch (e) {
        _errorMessage = e.toString();
        success = false;
      }
    });
    return success;
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    bool success = false;
    await execute(() async {
      try {
        if (_shouldUseMockData()) {
          success = true;
        } else {
          await _apiService.post('$endpoint/change-password', {
            'currentPassword': currentPassword,
            'newPassword': newPassword,
          });
          success = true;
        }
      } catch (e) {
        _errorMessage = e.toString();
        success = false;
      }
    });
    return success;
  }

  /// Updates the user's profile image
  Future<bool> updateProfileImage(String imagePath) async {
    bool success = false;
    await execute(() async {
      try {
        if (_shouldUseMockData()) {
          // In mock mode, just update the current user's image
          if (_currentUser != null) {
            _currentUser = _currentUser!.copyWith(profileImage: imagePath);
          }
          success = true;
        } else {
          // In real API mode, this would upload the image to a server
          // and get back the image URL
          // For now, simulate a successful upload
          await _apiService.post('$endpoint/upload-profile-image', {
            'imagePath': imagePath,
          });

          if (_currentUser != null) {
            // In a real scenario, we'd get the URL back from the server
            _currentUser = _currentUser!.copyWith(profileImage: imagePath);
          }
          success = true;
        }
        notifyListeners();
      } catch (e) {
        _errorMessage = e.toString();
        success = false;
      }
    });
    return success;
  }

  /// Updates the current user's address details in the provider state.
  void updateUserAddressDetails(AddressDetails? details) {
    if (_currentUser != null && details != null) {
      _currentUser = _currentUser!.copyWith(
        formattedAddress: details.formattedAddress,
        streetNumber: details.streetNumber,
        streetName: details.streetName,
        city: details.city,
        postalCode: details.postalCode,
        country: details.country,
        latitude: details.latitude,
        longitude: details.longitude,
      );
      notifyListeners();
    } else if (_currentUser != null && details == null) {
      // Clear address fields if details are null (e.g., address cleared by user)
      _currentUser = _currentUser!.copyWith(
        formattedAddress: null,
        streetNumber: null,
        streetName: null,
        city: null,
        postalCode: null,
        country: null,
        latitude: null,
        longitude: null,
      );
      notifyListeners();
    }
  }

  // Mock PayPal linking methods
  Future<void> linkPaypalAccount(String paypalEmail) async {
    // Simulate API call and SDK interaction
    if (_currentUser == null) return;
    setState(ViewState.Busy); // Set loading state
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    // In a real scenario, you would get the PayPal identifier from the SDK callback
    // and validate the provided paypalEmail through the SDK/API.
    _currentUser = _currentUser!.copyWith(
      isPaypalLinked: true,
      paypalUserIdentifier: paypalEmail, // Use provided email
    );
    setState(ViewState.Idle); // Set back to idle
    notifyListeners();
  }

  Future<void> unlinkPaypalAccount() async {
    if (_currentUser == null) return;
    setState(ViewState.Busy);
    await Future.delayed(const Duration(seconds: 1));

    _currentUser = _currentUser!.copyWith(
      isPaypalLinked: false,
      paypalUserIdentifier: null,
    );
    setState(ViewState.Idle);
    notifyListeners();
  }
}
