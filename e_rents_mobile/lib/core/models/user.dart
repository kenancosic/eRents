import './address.dart';

class User {
  final int? userId;
  final String username;
  final String email;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? role;
  final String? firstName;
  final String? lastName;
  final int? profileImageId;
  final String? password;
  final String? token;
  final bool? isPublic;
  final Address? address;

  // ✅ NEW CRITICAL FIELDS for backend alignment
  final int? userTypeId; // Backend expects userTypeId
  final DateTime? createdAt; // Backend tracks creation time
  final DateTime? updatedAt; // Backend tracks updates
  final List<String>? paymentMethods; // Available payment methods

  User({
    this.userId,
    required this.username,
    required this.email,
    this.phoneNumber,
    this.dateOfBirth,
    this.role,
    this.firstName,
    this.lastName,
    this.profileImageId,
    this.password,
    this.token,
    this.isPublic,
    this.address,
    // New fields
    this.userTypeId,
    this.createdAt,
    this.updatedAt,
    this.paymentMethods,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle ID parsing with type conversion
    int? userId;
    if (json['userId'] != null) {
      userId = json['userId'] is int 
          ? json['userId'] 
          : int.tryParse(json['userId'].toString());
    }
    
    int? profileImageId;
    if (json['profileImageId'] != null) {
      profileImageId = json['profileImageId'] is int 
          ? json['profileImageId'] 
          : int.tryParse(json['profileImageId'].toString());
    }
    
    int? userTypeId;
    if (json['userTypeId'] != null) {
      userTypeId = json['userTypeId'] is int 
          ? json['userTypeId'] 
          : int.tryParse(json['userTypeId'].toString());
    }
    
    // Handle date parsing with better error handling
    DateTime? dateOfBirth;
    try {
      if (json['dateOfBirth'] != null) {
        dateOfBirth = DateTime.parse(json['dateOfBirth'] is String 
            ? json['dateOfBirth'] 
            : json['dateOfBirth'].toString());
      }
    } catch (e) {
      print('Error parsing user dateOfBirth: $e');
    }
    
    DateTime? createdAt;
    try {
      if (json['createdAt'] != null) {
        createdAt = DateTime.parse(json['createdAt'] is String 
            ? json['createdAt'] 
            : json['createdAt'].toString());
      }
    } catch (e) {
      print('Error parsing user createdAt: $e');
    }
    
    DateTime? updatedAt;
    try {
      if (json['updatedAt'] != null) {
        updatedAt = DateTime.parse(json['updatedAt'] is String 
            ? json['updatedAt'] 
            : json['updatedAt'].toString());
      }
    } catch (e) {
      print('Error parsing user updatedAt: $e');
    }
    
    // Handle boolean parsing with type conversion
    bool? isPublic;
    if (json['isPublic'] != null) {
      isPublic = json['isPublic'] is bool 
          ? json['isPublic'] 
          : json['isPublic'].toString().toLowerCase() == 'true';
    }
    
    // Handle list parsing
    List<String>? paymentMethods;
    if (json['paymentMethods'] != null) {
      try {
        if (json['paymentMethods'] is List) {
          paymentMethods = List<String>.from(json['paymentMethods']);
        } else {
          // Handle case where it might be a string representation of a list
          paymentMethods = List<String>.from(json['paymentMethods'].toString()
              .split(',')
              .map((s) => s.trim()));
        }
      } catch (e) {
        print('Error parsing user paymentMethods: $e');
      }
    }
    
    // Build address from either legacy nested object or new flattened fields
    // Backend UserResponse uses PascalCase (City, Country, etc.)
    Address? parsedAddress;
    if (json['addressDetail'] != null && json['addressDetail'] is Map<String, dynamic>) {
      parsedAddress = Address.fromJson(json['addressDetail'] as Map<String, dynamic>);
    } else if (_hasAddressFields(json)) {
      // Backend UserResponse flattens address fields on root; Address.fromJson can handle flat maps
      parsedAddress = Address.fromJson(json);
    }

    return User(
      userId: userId,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString(),
      dateOfBirth: dateOfBirth,
      role: json['role']?.toString() ?? json['userType']?.toString(),
      firstName: json['firstName']?.toString() ?? json['name']?.toString(),
      lastName: json['lastName']?.toString(),
      profileImageId: profileImageId,
      password: json['password']?.toString(),
      token: json['resetToken']?.toString(),
      isPublic: isPublic,
      address: parsedAddress,
      // New fields parsing
      userTypeId: userTypeId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      paymentMethods: paymentMethods,
    );
  }

  /// Check for address fields in both camelCase and PascalCase
  static bool _hasAddressFields(Map<String, dynamic> json) {
    return json.containsKey('streetLine1') || json.containsKey('StreetLine1') ||
           json.containsKey('city') || json.containsKey('City') ||
           json.containsKey('country') || json.containsKey('Country') ||
           json.containsKey('state') || json.containsKey('State');
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'profileImageId': profileImageId,
      'password': password,
      'resetToken': token,
      'isPublic': isPublic,
      'addressDetail': address?.toAddressDetailJson(),
      // New fields
      'userTypeId': userTypeId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'paymentMethods': paymentMethods,
    };
  }

  User copyWith({
    int? userId,
    String? username,
    String? email,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? role,
    String? firstName,
    String? lastName,
    int? profileImageId,
    String? password,
    String? token,
    bool? isPublic,
    Address? address,
    int? userTypeId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? paymentMethods,
  }) {
    return User(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImageId: profileImageId ?? this.profileImageId,
      password: password ?? this.password,
      token: token ?? this.token,
      isPublic: isPublic ?? this.isPublic,
      address: address ?? this.address,
      userTypeId: userTypeId ?? this.userTypeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentMethods: paymentMethods ?? this.paymentMethods,
    );
  }

  String? get name => firstName;
  String? get userType => role;
  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
}
