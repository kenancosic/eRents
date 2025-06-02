/// Enum representing the different states a provider can be in
enum ProviderState {
  /// The provider is idle and not performing any operations
  idle,

  /// The provider is currently loading data
  loading,

  /// The provider has encountered an error
  error,

  /// The provider has successfully loaded data
  success,

  /// The provider is refreshing existing data
  refreshing,

  /// The provider is performing a background operation
  backgroundLoading,
}

/// Extension methods for ProviderState to make working with states easier
extension ProviderStateExtension on ProviderState {
  /// Returns true if the provider is currently performing any loading operation
  bool get isLoading =>
      this == ProviderState.loading ||
      this == ProviderState.refreshing ||
      this == ProviderState.backgroundLoading;

  /// Returns true if the provider is in an error state
  bool get isError => this == ProviderState.error;

  /// Returns true if the provider is idle and not performing operations
  bool get isIdle => this == ProviderState.idle;

  /// Returns true if the provider has successfully loaded data
  bool get isSuccess => this == ProviderState.success;

  /// Returns true if the provider is refreshing data (used for pull-to-refresh)
  bool get isRefreshing => this == ProviderState.refreshing;

  /// Returns true if the provider is loading data in the background without showing a loading indicator
  bool get isBackgroundLoading => this == ProviderState.backgroundLoading;

  /// Returns true if the provider can accept new requests
  bool get canAcceptRequests =>
      this == ProviderState.idle ||
      this == ProviderState.success ||
      this == ProviderState.error;

  /// Returns a human-readable description of the state
  String get description {
    switch (this) {
      case ProviderState.idle:
        return 'Idle';
      case ProviderState.loading:
        return 'Loading';
      case ProviderState.error:
        return 'Error';
      case ProviderState.success:
        return 'Success';
      case ProviderState.refreshing:
        return 'Refreshing';
      case ProviderState.backgroundLoading:
        return 'Background Loading';
    }
  }
}
