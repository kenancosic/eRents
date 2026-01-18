/// Enum representing the different states a provider can be in
enum ProviderState {
  /// Initial state when provider is first created
  initial,
  
  /// Loading state during async operations
  loading,
  
  /// Success state when operation completed successfully
  success,
  
  /// Error state when operation failed
  error,
  
  /// Empty state when data exists but is empty
  empty,
}

/// Extension methods for ProviderState enum
extension ProviderStateExtension on ProviderState {
  /// Check if provider is in loading state
  bool get isLoading => this == ProviderState.loading;
  
  /// Check if provider is in success state
  bool get isSuccess => this == ProviderState.success;
  
  /// Check if provider is in error state
  bool get isError => this == ProviderState.error;
  
  /// Check if provider is in initial state
  bool get isInitial => this == ProviderState.initial;
  
  /// Check if provider is in empty state
  bool get isEmpty => this == ProviderState.empty;
  
  /// Check if provider has data (success or empty)
  bool get hasData => this == ProviderState.success || this == ProviderState.empty;
  
  /// Check if provider can perform operations (not loading)
  bool get canPerformOperations => !isLoading;
}