import 'package:flutter/material.dart';
import 'core/app_config.dart';
import 'design/astride_theme.dart';
import 'services/api_client.dart';
import 'services/pinned_transport.dart';
import 'services/app_attestation_service.dart';
import 'services/session_store.dart';
import 'state/passenger_controller.dart';
import 'screens/passenger_root.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.validate();
  await PinnedTransport.initialize();
  await AppAttestationService.instance.initialize();
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
          theme: buildAstrideTheme(),
          home: PassengerRoot(controller: controller),
        ),
      );
}
