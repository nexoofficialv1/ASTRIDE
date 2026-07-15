import 'package:flutter_test/flutter_test.dart';

import 'package:astride_partner/core/app_config.dart';

void main() {
  test('production API endpoint is HTTPS', () {
    expect(AppConfig.apiBaseUrl.startsWith('https://'), isTrue);
  });
}
