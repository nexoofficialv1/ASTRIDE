import 'package:flutter/material.dart';
import 'core/app_config.dart';
import 'design/astride_theme.dart';
import 'services/api_client.dart';
import 'services/session_store.dart';
import 'state/driver_controller.dart';
import 'screens/driver_root.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.validate();
  final controller = DriverController(ApiClient(), SessionStore())..bootstrap();
  runApp(DriverApp(controller: controller));
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key, required this.controller});
  final DriverController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ASTRIDE Driver',
          theme: buildAstrideTheme(),
          home: DriverRoot(controller: controller),
        ),
      );
}
