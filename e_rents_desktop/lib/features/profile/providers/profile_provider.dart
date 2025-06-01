import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/address_detail.dart';
import 'package:e_rents_desktop/models/geo_region.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/services/profile_service.dart';
import 'dart:convert';
import 'package:e_rents_desktop/widgets/inputs/google_address_input.dart';
import 'package:e_rents_desktop/models/auth/change_password_request_model.dart';
import 'package:e_rents_desktop/models/image_info.dart' as erents;

class ProfileProvider extends BaseProvider<User> {
  final ProfileService _profileService;
  User? _currentUser;

  ProfileProvider(this._profileService) : super(_profileService) {}

  User? get currentUser => _currentUser;

  @override
  String get endpoint => '/profile';

  @override
  User fromJson(Map<String, dynamic> json) => User.fromJson(json);

  @override
  Map<String, dynamic> toJson(User item) => item.toJson();

  Future<void> fetchUserProfile() async {
    await execute(() async {
      _currentUser = await _profileService.getMyProfile();
    });
  }

  Future<bool> updateProfile(User user) async {
    bool success = false;
    await execute(() async {
      // Send the update request
      _currentUser = await _profileService.updateMyProfile(user);
      success = true;
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
      await _profileService.changePassword(request);
      success = true;
    });
    return success;
  }

  Future<bool> updateProfileImage(String imagePath) async {
    bool success = false;
    await execute(() async {
      final updatedUser = await _profileService.uploadProfileImage(imagePath);
      _currentUser = updatedUser;
      success = true;
    });
    return success;
  }

  Future<bool> linkPaypalAccount(String paypalEmail) async {
    bool success = false;
    await execute(() async {
      final updatedUser = await _profileService.linkPaypal(paypalEmail);
      _currentUser = updatedUser;
      success = true;
    });
    return success;
  }

  Future<bool> unlinkPaypalAccount() async {
    bool success = false;
    await execute(() async {
      final updatedUser = await _profileService.unlinkPaypal();
      _currentUser = updatedUser;
      success = true;
    });
    return success;
  }

  AddressDetail _convertToAddressDetail(AddressDetails details) {
    String streetLine1 = '';
    if (details.streetNumber != null && details.streetName != null) {
      streetLine1 = '${details.streetNumber} ${details.streetName}';
    } else {
      streetLine1 = details.formattedAddress;
    }

    // Use the best available city name
    final cityName = details.bestCityName ?? details.city;

    // Determine the state/entity for Bosnia and Herzegovina
    String? state = details.bosnianEntity;

    // If no entity found but we have administrative area, try to map it
    if (state == null && details.administrativeAreaLevel1 != null) {
      state = _mapAdministrativeAreaToEntity(details.administrativeAreaLevel1!);
    }

    return AddressDetail(
      addressDetailId: _currentUser?.addressDetail?.addressDetailId ?? 0,
      geoRegionId: null, // Don't send GeoRegionId, let backend find/create it
      streetLine1: streetLine1,
      streetLine2:
          details.sublocality != null
              ? '${details.sublocality}, ${details.country ?? 'Bosnia and Herzegovina'}'
              : (cityName != null
                  ? '${cityName}, ${details.country ?? 'Bosnia and Herzegovina'}'
                  : null),
      latitude: details.latitude,
      longitude: details.longitude,
      geoRegion:
          cityName != null
              ? GeoRegion(
                city: cityName,
                state: state,
                country: details.country ?? 'Bosnia and Herzegovina',
                postalCode: details.postalCode,
              )
              : null,
    );
  }

  /// Maps Google Places administrative_area_level_1 to Bosnia and Herzegovina entities
  String? _mapAdministrativeAreaToEntity(String adminArea) {
    final normalized = adminArea.toLowerCase().trim();

    // Map common Google Places API responses to standard entity names
    if (normalized.contains('federation') ||
        normalized.contains('federacija') ||
        normalized == 'fbih' ||
        normalized.contains('federation of bosnia and herzegovina')) {
      return 'Federation of Bosnia and Herzegovina';
    }

    if (normalized.contains('republika srpska') ||
        normalized == 'rs' ||
        normalized == 'republika srpska') {
      return 'Republika Srpska';
    }

    if (normalized.contains('brčko') ||
        normalized.contains('brcko') ||
        normalized.contains('brčko district')) {
      return 'Brčko District';
    }

    // If we can't map it, return the original value
    return adminArea;
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

  void updateUserPersonalInfo(
    String firstName,
    String lastName,
    String? phone,
  ) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      notifyListeners();
    }
  }

  void updateUserAddressFromString(String addressString) {
    if (_currentUser != null && addressString.isNotEmpty) {
      // Parse city, state, country from address string
      final parsedLocation = _parseAddressString(addressString);

      // Ensure we have at least a city to create a proper GeoRegion
      if (parsedLocation['city'] == null || parsedLocation['city']!.isEmpty) {
        // If no city parsed, try to extract it differently
        final parts = addressString.split(',').map((e) => e.trim()).toList();
        if (parts.length >= 2) {
          parsedLocation['city'] = parts[1]; // Use second part as city
        } else {
          parsedLocation['city'] = 'Unknown'; // Fallback
        }
      }

      final addressDetail = AddressDetail(
        addressDetailId: _currentUser?.addressDetail?.addressDetailId ?? 0,
        geoRegionId: null, // Don't send GeoRegionId, let backend find/create it
        streetLine1: addressString,
        streetLine2: null, // Don't duplicate country in streetLine2
        latitude: null,
        longitude: null,
        geoRegion: GeoRegion(
          city: parsedLocation['city']!,
          state: parsedLocation['state'],
          country: parsedLocation['country'] ?? 'Bosnia and Herzegovina',
          postalCode: null,
        ),
      );

      _currentUser = _currentUser!.copyWith(addressDetail: addressDetail);
      notifyListeners();
    }
  }

  /// Parse address string to extract city, state, and country
  /// Enhanced for Bosnia and Herzegovina entity detection
  Map<String, String?> _parseAddressString(String addressString) {
    // Handle format: "Street, City, Country" or "Street, City, State, Country"
    final parts = addressString.split(',').map((e) => e.trim()).toList();

    String? city;
    String? state;
    String? country;

    if (parts.length >= 2) {
      if (parts.length == 3) {
        // Format: "Street, City, Country"
        city = parts[1];
        country = parts[2];
      } else if (parts.length >= 4) {
        // Format: "Street, City, State, Country"
        city = parts[1];
        state = parts[2];
        country = parts[3];
      } else {
        // Format: "Street, City"
        city = parts[1];
        country = 'Bosnia and Herzegovina'; // Default for this region
      }
    } else {
      // Single part - treat whole string as street, no city extracted
      city = null;
      country = 'Bosnia and Herzegovina';
    }

    // Try to detect entity from city name if we have a city but no state
    if (city != null &&
        state == null &&
        country?.toLowerCase().contains('bosnia') == true) {
      state = _detectEntityFromCity(city);
    }

    // If we have a potential entity name in state, try to map it
    if (state != null && country?.toLowerCase().contains('bosnia') == true) {
      final mappedState = _mapAdministrativeAreaToEntity(state);
      if (mappedState != state) {
        state = mappedState;
      }
    }

    return {'city': city, 'state': state, 'country': country};
  }

  /// Detect Bosnia and Herzegovina entity from city name
  String? _detectEntityFromCity(String cityName) {
    final normalized = cityName.toLowerCase().trim();

    // Federation of Bosnia and Herzegovina cities (major ones)
    const federationCities = {
      'sarajevo',
      'mostar',
      'tuzla',
      'zenica',
      'lukavac',
      'gradačac',
      'gračanica',
      'sanski most',
      'cazin',
      'bihać',
      'livno',
      'bugojno',
      'travnik',
      'jajce',
      'konjic',
      'goražde',
      'fojnica',
      'kiseljak',
      'vitez',
      'novi travnik',
      'jablanica',
      'neum',
      'stolac',
      'čapljina',
    };

    // Republika Srpska cities (major ones)
    const republikaSrpskaCities = {
      'banja luka',
      'bijeljina',
      'prijedor',
      'doboj',
      'gradiška',
      'zvornik',
      'trebinje',
      'istočno sarajevo',
      'pale',
      'sokolac',
      'rogatica',
      'višegrad',
      'nevesinje',
      'gacko',
      'laktaši',
      'čelinac',
      'prnjavor',
      'derventa',
      'modriča',
      'ugljevik',
      'srebrenica',
      'bratunac',
    };

    // Brčko District
    const brckoDistrict = {'brčko'};

    if (federationCities.contains(normalized)) {
      return 'Federation of Bosnia and Herzegovina';
    } else if (republikaSrpskaCities.contains(normalized)) {
      return 'Republika Srpska';
    } else if (brckoDistrict.contains(normalized)) {
      return 'Brčko District';
    }

    // Return null if city is not recognized - let backend handle it
    return null;
  }

  @override
  List<User> getMockItems() {
    return [
      User(
        id: 1,
        email: 'testLandlord@example.ba',
        username: 'marko_vlajic',
        firstName: 'Marko',
        lastName: 'Vlajić',
        phone: '38761821547',
        role: UserType.landlord,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        updatedAt: DateTime.now(),
        isPaypalLinked: false,
        paypalUserIdentifier: null,
        profileImage: erents.ImageInfo(
          id: 1,
          url: 'assets/images/user-image.png',
        ),
        addressDetail: AddressDetail(
          addressDetailId: 1,
          geoRegionId: 1,
          streetLine1: 'Lukavačkih brigada, Lukavac, Bosnia and Herzegovina',
          streetLine2: null,
          latitude: 44.5369,
          longitude: 18.5281,
        ),
      ),
    ];
  }
}
