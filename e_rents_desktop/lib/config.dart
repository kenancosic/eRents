class Config {
  // API base URLs - centralized configuration point
  // Desktop uses localhost for local development
  static const String baseUrl = 'http://localhost:5000/api'; // Desktop/Web
  
  // All other config (Stripe keys, etc.) loaded from lib/.env via flutter_dotenv
}
