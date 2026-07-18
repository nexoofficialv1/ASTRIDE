import 'package:flutter/material.dart';
import '../../design/astride_theme.dart';
class AstrideStatusCard extends StatelessWidget {
  const AstrideStatusCard({super.key,required this.icon,required this.title,required this.subtitle,this.trailing});
  final IconData icon; final String title; final String subtitle; final Widget? trailing;
  @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Row(children:[Container(width:52,height:52,decoration:BoxDecoration(color:const Color(0x1422C55E),borderRadius:BorderRadius.circular(16)),child:Icon(icon,color:AstrideColors.green)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w700,fontSize:16)),const SizedBox(height:4),Text(subtitle,style:const TextStyle(color:AstrideColors.muted))])),if(trailing!=null)trailing!]))) ;
}
