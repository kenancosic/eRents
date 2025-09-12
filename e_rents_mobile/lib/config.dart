class Config {
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android emulator
  static const String baseLocalhostUrl = 'http://localhost:5000/api';
  static const String rabbitMQHost = 'rabbitmq.erents.com';
  static const String paymentGatewayApiKey = 'PRODUCTION_API_KEY';
  // PayPal Native SDK configuration
  // NOTE: Ensure this matches the backend PayPalOptions.ClientId and environment
  static const String paypalClientId = 'AUVM87eSBUVvxOZm-QoMuiYEk-xr9E6TTSx-HBE5BBG2GyM71iI-JD3p3yv99V4VI62pmSAWNMtFLQDT';
  static const bool paypalSandbox = true; // set to false in production
  // Return URL scheme must have no underscore and be declared in platform configs if required
  static const String paypalReturnUrl = 'com.erents.mobile://paypalpay';
}
