import 'package:flutter/material.dart';
import '../../design/astride_theme.dart';
class DriverSearchingScreen extends StatelessWidget {
 const DriverSearchingScreen({super.key,required this.title,required this.cancelLabel,required this.onCancel});
 final String title,cancelLabel; final VoidCallback onCancel;
 @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Padding(padding:const EdgeInsets.all(24),child:Column(children:[const Spacer(),Stack(alignment:Alignment.center,children:[SizedBox(width:210,height:210,child:CircularProgressIndicator(strokeWidth:7,color:AstrideColors.green)),Container(width:150,height:150,decoration:const BoxDecoration(color:AstrideColors.navy,shape:BoxShape.circle),child:const Icon(Icons.electric_rickshaw_rounded,size:86,color:Colors.white))]),const SizedBox(height:42),Text(title,textAlign:TextAlign.center,style:const TextStyle(fontSize:25,fontWeight:FontWeight.w800,color:AstrideColors.navy)),const SizedBox(height:12),const Text('Please stay on this screen while we connect you with the nearest verified driver.',textAlign:TextAlign.center,style:TextStyle(color:AstrideColors.muted,height:1.5)),const Spacer(),SizedBox(width:double.infinity,child:OutlinedButton(onPressed:onCancel,child:Text(cancelLabel)))]))));
}
