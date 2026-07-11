import 'package:flutter/material.dart';
import '../state/passenger_controller.dart';
import 'language_screen.dart';
import 'login_screen.dart';
import 'passenger_shell.dart';
import 'onboarding/splash_screen.dart';
class PassengerRoot extends StatelessWidget{const PassengerRoot({super.key,required this.controller});final PassengerController controller;@override Widget build(BuildContext context){if(controller.loading)return const SplashScreen();if(controller.locale==null)return LanguageScreen(onSelect:controller.selectLanguage);if(controller.config.maintenanceMode||!controller.config.serviceEnabled)return Scaffold(body:Center(child:Padding(padding:const EdgeInsets.all(24),child:Text(controller.t('system.maintenance'),textAlign:TextAlign.center,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w700)))));if(controller.session==null)return LoginScreen(controller:controller);return PassengerShell(controller:controller);}}
