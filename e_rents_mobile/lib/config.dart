class Config {
  // API base URLs - centralized configuration point
  // Android emulator uses 10.0.2.2 to reach host machine's localhost
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android emulator (AVD)
  static const String baseLocalhostUrl = 'http://localhost:5000/api'; // Desktop/Web
  
  // All other config (Stripe keys, etc.) loaded from lib/.env via flutter_dotenv
}
