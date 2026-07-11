import 'package:flutter/material.dart';
import '../../design/astride_theme.dart';
import '../../widgets/brand/astride_wordmark.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.t, required this.onDone});
  final String Function(String) t;
  final VoidCallback onDone;
  @override State<OnboardingScreen> createState() => _OnboardingScreenState();
}
class _OnboardingScreenState extends State<OnboardingScreen> {
  final page = PageController(); int index = 0;
  late final items = [
    (Icons.electric_rickshaw_rounded, 'onboarding.fastTitle', 'onboarding.fastBody'),
    (Icons.shield_rounded, 'onboarding.safeTitle', 'onboarding.safeBody'),
    (Icons.location_on_rounded, 'onboarding.trackTitle', 'onboarding.trackBody'),
  ];
  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Column(children: [
      const Padding(padding: EdgeInsets.all(24), child: Align(alignment: Alignment.centerLeft, child: AstrideWordmark(compact: true))),
      Expanded(child: PageView.builder(controller: page, itemCount: items.length, onPageChanged: (v)=>setState(()=>index=v), itemBuilder: (_,i){final x=items[i];return Padding(padding: const EdgeInsets.all(28),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Container(width:170,height:170,decoration:const BoxDecoration(color:Color(0x1422C55E),shape:BoxShape.circle),child:Icon(x.$1,size:92,color:AstrideColors.green)),const SizedBox(height:36),Text(widget.t(x.$2),textAlign:TextAlign.center,style:const TextStyle(fontSize:28,fontWeight:FontWeight.w800,color:AstrideColors.navy)),const SizedBox(height:14),Text(widget.t(x.$3),textAlign:TextAlign.center,style:const TextStyle(fontSize:16,height:1.5,color:AstrideColors.muted))]));})),
      Row(mainAxisAlignment:MainAxisAlignment.center,children:List.generate(items.length,(i)=>AnimatedContainer(duration:const Duration(milliseconds:200),margin:const EdgeInsets.all(4),width:i==index?26:8,height:8,decoration:BoxDecoration(color:i==index?AstrideColors.green:AstrideColors.border,borderRadius:BorderRadius.circular(8))))),
      Padding(padding:const EdgeInsets.all(24),child:SizedBox(width:double.infinity,child:FilledButton(onPressed:(){if(index<items.length-1){page.nextPage(duration:const Duration(milliseconds:250),curve:Curves.easeOut);}else{widget.onDone();}},child:Text(index==items.length-1?widget.t('common.getStarted'):widget.t('common.next')))))
    ])),
  );
}
