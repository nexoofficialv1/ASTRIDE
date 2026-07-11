import 'package:flutter/material.dart';
import 'design/astride_theme.dart';
import 'services/api_client.dart';
import 'services/session_store.dart';
import 'state/passenger_controller.dart';
import 'screens/passenger_root.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = PassengerController(ApiClient(), SessionStore())..bootstrap();
  runApp(PassengerApp(controller: controller));
}

class PassengerApp extends StatelessWidget {
  const PassengerApp({super.key, required this.controller});
  final PassengerController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ASTRIDE',
          theme: AstrideTheme.light(),
          home: PassengerRoot(controller: controller),
        ),
      );
}
