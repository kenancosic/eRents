// lib/features/checkout/models/payment_state.dart

/// Enum representing the various states of a payment process
enum PaymentState {
  /// Initial state - no payment in progress
  idle,
  
  /// Creating payment intent on backend
  creatingIntent,
  
  /// Presenting Stripe payment sheet to user
  presentingSheet,
  
  /// Processing payment with Stripe
  processing,
  
  /// Payment succeeded
  success,
  
  /// Payment failed or was cancelled
  failed,
  
  /// Payment was cancelled by user
  cancelled,
}

/// Extension to provide helpful state checks
extension PaymentStateExtension on PaymentState {
  bool get isLoading =>
      this == PaymentState.creatingIntent ||
      this == PaymentState.processing;
  
  bool get canRetry =>
      this == PaymentState.failed ||
      this == PaymentState.cancelled;
  
  bool get isTerminal =>
      this == PaymentState.success ||
      this == PaymentState.failed;
}
