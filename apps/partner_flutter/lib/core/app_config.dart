class AppConfig {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://astaride.nexoofficial.in');
  static const requestTimeout = Duration(seconds: 20);
}
