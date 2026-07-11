import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session.dart';
class SessionStore {
  static const _secure=FlutterSecureStorage();
  Future<void> save(Session s) async {await _secure.write(key:'token',value:s.token);await _secure.write(key:'userId',value:s.userId);await _secure.write(key:'mobile',value:s.mobile);}
  Future<Session?> read() async {final t=await _secure.read(key:'token');final id=await _secure.read(key:'userId');final m=await _secure.read(key:'mobile');return t==null||id==null||m==null?null:Session(userId:id,token:t,mobile:m);}
  Future<void> clear()=>_secure.deleteAll();
  Future<String?> language() async=>(await SharedPreferences.getInstance()).getString('language');
  Future<void> saveLanguage(String v) async=>(await SharedPreferences.getInstance()).setString('language',v);
}
