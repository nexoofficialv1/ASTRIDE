import 'package:flutter/material.dart';
import '../../design/astride_theme.dart';
import '../../state/driver_controller.dart';
import '../../widgets/brand/astride_wordmark.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key, required this.controller});
  final DriverController controller;
  @override State<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}
class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final name = TextEditingController(), address = TextEditingController(), vehicle = TextEditingController(), upi = TextEditingController(), emergency = TextEditingController();
  @override Widget build(BuildContext context) { final c=widget.controller; return Scaffold(
    appBar: AppBar(title: const AstrideWordmark(compact:true)),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Text(c.t('completeProfile'), style: const TextStyle(fontSize:26,fontWeight:FontWeight.w800,color:AstrideColors.navy)),
      const SizedBox(height:6), Text(c.t('profileStepOne'), style: const TextStyle(color:AstrideColors.muted)),
      const SizedBox(height:20),
      TextField(controller:name,decoration:InputDecoration(labelText:c.t('fullName'),prefixIcon:const Icon(Icons.person_outline))),
      const SizedBox(height:12), TextField(controller:address,maxLines:2,decoration:InputDecoration(labelText:c.t('address'),prefixIcon:const Icon(Icons.home_outlined))),
      const SizedBox(height:12), TextField(controller:vehicle,decoration:InputDecoration(labelText:c.t('vehicleNumber'),prefixIcon:const Icon(Icons.electric_rickshaw_outlined))),
      const SizedBox(height:12), TextField(controller:upi,decoration:InputDecoration(labelText:c.t('upiId'),prefixIcon:const Icon(Icons.account_balance_wallet_outlined))),
      const SizedBox(height:12), TextField(controller:emergency,keyboardType:TextInputType.phone,decoration:InputDecoration(labelText:c.t('emergencyContact'),prefixIcon:const Icon(Icons.emergency_outlined))),
      const SizedBox(height:22), FilledButton(onPressed:()=>c.saveProfile({'name':name.text,'address':address.text,'vehicleNumber':vehicle.text,'upiId':upi.text,'emergencyContact':emergency.text}),child:Text(c.t('saveAndContinue'))),
    ]),
  ); }
}
