// lib/features/profile/models/connect_account_status.dart

/// Model representing the status of a Stripe Connect account
class ConnectAccountStatus {
  final String? accountId;
  final bool chargesEnabled;
  final bool payoutsEnabled;
  final bool detailsSubmitted;
  final bool isActive;
  final String? statusMessage;
  final List<String>? currentlyDue;
  final List<String>? eventuallyDue;

  ConnectAccountStatus({
    this.accountId,
    required this.chargesEnabled,
    required this.payoutsEnabled,
    required this.detailsSubmitted,
    required this.isActive,
    this.statusMessage,
    this.currentlyDue,
    this.eventuallyDue,
  });

  /// Check if account setup is complete
  bool get isComplete => detailsSubmitted && chargesEnabled && payoutsEnabled;

  /// Check if account has pending requirements
  bool get hasPendingRequirements =>
      (currentlyDue != null && currentlyDue!.isNotEmpty) ||
      (eventuallyDue != null && eventuallyDue!.isNotEmpty);

  /// Get account status category
  ConnectAccountState get state {
    if (!detailsSubmitted || hasPendingRequirements) {
      return ConnectAccountState.pending;
    }
    if (isActive && chargesEnabled && payoutsEnabled) {
      return ConnectAccountState.active;
    }
    return ConnectAccountState.inactive;
  }

  factory ConnectAccountStatus.fromJson(Map<String, dynamic> json) {
    return ConnectAccountStatus(
      accountId: json['accountId'] as String?,
      chargesEnabled: json['chargesEnabled'] as bool? ?? false,
      payoutsEnabled: json['payoutsEnabled'] as bool? ?? false,
      detailsSubmitted: json['detailsSubmitted'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? false,
      statusMessage: json['statusMessage'] as String?,
      currentlyDue: (json['currentlyDue'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      eventuallyDue: (json['eventuallyDue'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'chargesEnabled': chargesEnabled,
      'payoutsEnabled': payoutsEnabled,
      'detailsSubmitted': detailsSubmitted,
      'isActive': isActive,
      'statusMessage': statusMessage,
      'currentlyDue': currentlyDue,
      'eventuallyDue': eventuallyDue,
    };
  }

  @override
  String toString() {
    return 'ConnectAccountStatus(accountId: $accountId, isActive: $isActive, state: $state)';
  }
}

/// Enum representing the state of a Connect account
enum ConnectAccountState {
  /// Account is fully active and operational
  active,

  /// Account has pending information or verification
  pending,

  /// Account is not active or has issues
  inactive,
}

/// Model for onboarding link response
class OnboardingLinkResponse {
  final String accountId;
  final String onboardingUrl;
  final int expiresAt;

  OnboardingLinkResponse({
    required this.accountId,
    required this.onboardingUrl,
    required this.expiresAt,
  });

  factory OnboardingLinkResponse.fromJson(Map<String, dynamic> json) {
    return OnboardingLinkResponse(
      accountId: json['accountId'] as String,
      onboardingUrl: json['onboardingUrl'] as String,
      expiresAt: json['expiresAt'] as int,
    );
  }

  /// Check if the onboarding link has expired
  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= expiresAt;
  }
}
