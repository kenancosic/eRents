import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/address_detail.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/services/profile_service.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';
import 'dart:convert';
import 'package:e_rents_desktop/widgets/inputs/google_address_input.dart';
import 'package:e_rents_desktop/models/auth/change_password_request_model.dart';
import 'package:e_rents_desktop/models/image_info.dart' as erents;

class ProfileProvider extends BaseProvider<User> {
  final ProfileService _profileService;
  User? _currentUser;

  ProfileProvider(this._profileService) : super(_profileService) {
    // enableMockData(); // Mock data control handled by BaseProvider or specific methods
  }

  User? get currentUser => _currentUser;

  @override
  String get endpoint => '/profile';

  @override
  User fromJson(Map<String, dynamic> json) => User.fromJson(json);

  @override
  Map<String, dynamic> toJson(User item) => item.toJson();

  @override
  List<User> getMockItems() {
    final mockUser = MockDataService.getMockUsers().first;
    return [
      mockUser.copyWith(
        addressDetail: AddressDetail(
          geoRegionId: 123,
          addressDetailId: 123,
          streetLine1: '123 Mock Street, Mockville',
          streetLine2: '',
        ),
      ),
    ];
  }

  Future<void> fetchUserProfile() async {
    await execute(() async {
      if (isMockDataEnabled) {
        _currentUser = getMockItems().first;
      } else {
        _currentUser = await _profileService.getMyProfile();
      }
    });
  }

  Future<bool> updateProfile(User user) async {
    bool success = false;
    await execute(() async {
      if (isMockDataEnabled) {
        _currentUser = user;
        success = true;
      } else {
        _currentUser = await _profileService.updateMyProfile(user.toJson());
        success = true;
      }
    });
    return success;
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    bool success = false;
    final request = ChangePasswordRequestModel(
      oldPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    await execute(() async {
      if (isMockDataEnabled) {
        success = true;
      } else {
        await _profileService.changePassword(request);
        success = true;
      }
    });
    return success;
  }

  Future<bool> updateProfileImage(String imagePath) async {
    bool success = false;
    await execute(() async {
      if (isMockDataEnabled) {
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(
            profileImage: erents.ImageInfo(id: imagePath, url: imagePath),
          );
        }
        success = true;
      } else {
        final updatedUser = await _profileService.uploadProfileImage(imagePath);
        _currentUser = updatedUser;
        success = true;
      }
    });
    return success;
  }

  Future<bool> linkPaypalAccount(String paypalEmail) async {
    bool success = false;
    await execute(() async {
      if (isMockDataEnabled) {
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(
            isPaypalLinked: true,
            paypalUserIdentifier: paypalEmail,
          );
        }
        success = true;
      } else {
        final updatedUser = await _profileService.linkPaypal(paypalEmail);
        _currentUser = updatedUser;
        success = true;
      }
    });
    return success;
  }

  Future<bool> unlinkPaypalAccount() async {
    bool success = false;
    await execute(() async {
      if (isMockDataEnabled) {
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(
            isPaypalLinked: false,
            paypalUserIdentifier: null,
          );
        }
        success = true;
      } else {
        final updatedUser = await _profileService.unlinkPaypal();
        _currentUser = updatedUser;
        success = true;
      }
    });
    return success;
  }

  AddressDetail _convertToAddressDetail(AddressDetails details) {
    const int defaultGeoRegionId = 1;
    String streetLine1 = '';
    if (details.streetNumber != null && details.streetName != null) {
      streetLine1 = '${details.streetNumber} ${details.streetName}';
    } else {
      streetLine1 = details.formattedAddress;
    }
    return AddressDetail(
      addressDetailId: _currentUser?.addressDetail?.addressDetailId ?? 0,
      geoRegionId:
          _currentUser?.addressDetail?.geoRegionId ?? defaultGeoRegionId,
      streetLine1: streetLine1,
      streetLine2:
          details.city != null ? '${details.city}, ${details.country}' : null,
      latitude: details.latitude,
      longitude: details.longitude,
    );
  }

  void updateUserAddressDetails(AddressDetails? details) {
    if (_currentUser != null && details != null) {
      final addressDetail = _convertToAddressDetail(details);
      _currentUser = _currentUser!.copyWith(addressDetail: addressDetail);
      notifyListeners();
    } else if (_currentUser != null && details == null) {
      _currentUser = _currentUser!.copyWith(addressDetail: null);
      notifyListeners();
    }
  }
}
