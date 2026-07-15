import 'package:flutter/material.dart';

import '../state/partner_controller.dart';
import 'partner_login_screen.dart';
import 'partner_shell.dart';

class PartnerRoot extends StatelessWidget {
  const PartnerRoot({super.key, required this.controller});
  final PartnerController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.bootstrapping) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return controller.isAuthenticated
        ? PartnerShell(controller: controller)
        : PartnerLoginScreen(controller: controller);
  }
}
