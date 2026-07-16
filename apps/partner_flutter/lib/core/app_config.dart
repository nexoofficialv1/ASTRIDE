class AppConfig {
  static const environment = String.fromEnvironment('APP_ENV', defaultValue: 'local');
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://astaride.nexoofficial.in',
  );
  static const enableDebugLogs = bool.fromEnvironment(
    'ENABLE_DEBUG_LOGS',
    defaultValue: false,
  );
  static const allowInsecureHttp = bool.fromEnvironment(
    'ALLOW_INSECURE_HTTP',
    defaultValue: false,
  );
  static const requestTimeout = Duration(seconds: 25);
  static const appVersion = '3.20.0+345';

  static bool get isProduction => environment == 'production';

  static void validate() {
    final api = Uri.tryParse(apiBaseUrl);
    if (api == null || !api.hasScheme || api.host.isEmpty) {
      throw StateError('Invalid API_BASE_URL');
    }
    if (isProduction && !apiBaseUrl.startsWith('https://')) {
      throw StateError('Production requires HTTPS');
    }
    if (!allowInsecureHttp && apiBaseUrl.startsWith('http://')) {
      throw StateError('Insecure HTTP is disabled');
    }
  }
}
