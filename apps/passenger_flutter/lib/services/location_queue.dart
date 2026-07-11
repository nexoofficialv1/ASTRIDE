import 'dart:convert';import 'package:shared_preferences/shared_preferences.dart';
class LocationQueue {static const key='pending_location_points';Future<void> add(Map<String,dynamic> p) async{final s=await SharedPreferences.getInstance();final l=s.getStringList(key)??[];l.add(jsonEncode(p));if(l.length>500)l.removeRange(0,l.length-500);await s.setStringList(key,l);}
 Future<List<Map<String,dynamic>>> read() async{final s=await SharedPreferences.getInstance();return (s.getStringList(key)??[]).map((e)=>(jsonDecode(e) as Map).cast<String,dynamic>()).toList();}
 Future<void> clear() async=>(await SharedPreferences.getInstance()).remove(key);}
