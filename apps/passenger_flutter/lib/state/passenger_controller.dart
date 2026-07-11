import 'dart:async';import 'package:flutter/foundation.dart';
import '../core/app_locale.dart';import '../models/runtime_config.dart';import '../models/session.dart';import '../services/api_client.dart';import '../services/session_store.dart';
class PassengerController extends ChangeNotifier {PassengerController(this.api,this.store);final ApiClient api;final SessionStore store;AppLocale? locale;Session? session;RuntimeConfig config=RuntimeConfig.fallback;bool loading=true;String? error;Map<String,dynamic>? activeBooking;
 Future<void> bootstrap() async{loading=true;notifyListeners();try{final code=await store.language();if(code!=null)locale=await AppLocale.load(code);session=await store.read();api.token=session?.token;final r=await api.getJson('/v1/mobile/config?app=PASSENGER&version=1.5.0');config=RuntimeConfig.fromJson((r['config']??r).cast<String,dynamic>());}catch(e){error=e.toString();}loading=false;notifyListeners();}
 Future<void> selectLanguage(String code) async{await store.saveLanguage(code);locale=await AppLocale.load(code);notifyListeners();}
 Future<void> login(String mobile,String otp) async{final r=await api.postJson('/v1/passengers/otp/verify',{'mobile':mobile,'otp':otp});session=Session(userId:(r['passengerId']??r['userId']??mobile).toString(),token:(r['token']??'dev-token').toString(),mobile:mobile);api.token=session!.token;await store.save(session!);notifyListeners();}
 Future<Map<String,dynamic>> estimate(Map<String,dynamic> pickup,Map<String,dynamic> destination) async=>api.postJson('/v1/fares/estimate',{'pickup':pickup,'destination':destination});
 Future<void> book(Map<String,dynamic> pickup,Map<String,dynamic> destination,String method) async{activeBooking=await api.postJson('/v1/bookings',{'passengerId':session!.userId,'pickup':pickup,'destination':destination,'paymentMethod':method});notifyListeners();}
 Future<void> cancel() async{if(activeBooking==null)return;await api.postJson('/v1/bookings/${activeBooking!['id']}/cancel',{'actor':'PASSENGER'});activeBooking=null;notifyListeners();}
 Future<void> logout() async{await store.clear();session=null;activeBooking=null;notifyListeners();}
 String t(String k)=>locale?.t(k)??k;}
