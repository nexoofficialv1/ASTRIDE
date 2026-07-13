import 'package:flutter/material.dart';

import 'design/astride_theme.dart';
import 'screens/change_password_screen.dart';
import 'screens/login_screen.dart';
import 'screens/partner_shell.dart';
import 'services/api_client.dart';
import 'services/session_store.dart';
import 'state/partner_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = PartnerController(
    ApiClient(),
    SessionStore(),
  )..bootstrap();

  runApp(PartnerApp(controller: controller));
}

class PartnerApp extends StatelessWidget {
  const PartnerApp({
    super.key,
    required this.controller,
  });

  final PartnerController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ASTRIDE Partner',
          theme: buildAstrideTheme(),
          home: controller.session == null
              ? LoginScreen(controller: controller)
              : controller.mustChangePassword
                  ? ChangePasswordScreen(controller: controller)
                  : PartnerShell(c: controller),
        ),
      );
}
