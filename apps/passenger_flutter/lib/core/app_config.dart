class AppConfig {
  static const environment = String.fromEnvironment('APP_ENV', defaultValue: 'local');
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3333',
  );
  static const wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://10.0.2.2:3333',
  );
  static const enableDebugLogs = bool.fromEnvironment(
    'ENABLE_DEBUG_LOGS',
    defaultValue: true,
  );
  static const allowInsecureHttp = bool.fromEnvironment(
    'ALLOW_INSECURE_HTTP',
    defaultValue: true,
  );

  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';

  static void validate() {
    final api = Uri.tryParse(apiBaseUrl);
    final ws = Uri.tryParse(wsBaseUrl);
    if (api == null || !api.hasScheme || api.host.isEmpty) {
      throw StateError('Invalid API_BASE_URL');
    }
    if (ws == null || !ws.hasScheme || ws.host.isEmpty) {
      throw StateError('Invalid WS_BASE_URL');
    }
    if (isProduction && (!apiBaseUrl.startsWith('https://') || !wsBaseUrl.startsWith('wss://'))) {
      throw StateError('Production requires HTTPS/WSS endpoints');
    }
    if (!allowInsecureHttp && apiBaseUrl.startsWith('http://')) {
      throw StateError('Insecure HTTP is disabled');
    }
  }
}
