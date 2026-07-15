import 'package:flutter/material.dart';

import 'core/app_config.dart';
import 'design/astride_theme.dart';
import 'screens/partner_root.dart';
import 'services/api_client.dart';
import 'services/session_store.dart';
import 'state/partner_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.validate();
  final controller = PartnerController(ApiClient(), SessionStore())..bootstrap();
  runApp(PartnerApp(controller: controller));
}

class PartnerApp extends StatelessWidget {
  const PartnerApp({super.key, required this.controller});
  final PartnerController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ASTRIDE Partner',
          theme: buildAstrideTheme(),
          home: PartnerRoot(controller: controller),
        ),
      );
}
