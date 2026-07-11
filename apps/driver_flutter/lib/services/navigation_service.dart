import 'dart:convert';
import 'package:http/http.dart' as http;
class NavigationRoute {final int distanceM;final int durationS;final String provider;const NavigationRoute(this.distanceM,this.durationS,this.provider);}
class NavigationService {
 final String apiBaseUrl; final http.Client client;
 NavigationService(this.apiBaseUrl,{http.Client? client}):client=client??http.Client();
 Future<NavigationRoute> route(double fromLat,double fromLng,double toLat,double toLng) async {
  final r=await client.post(Uri.parse('$apiBaseUrl/v1/maps/route'),headers:{'content-type':'application/json'},body:jsonEncode({'origin':{'lat':fromLat,'lng':fromLng},'destination':{'lat':toLat,'lng':toLng}}));
  if(r.statusCode!=200) throw StateError('Navigation route failed'); final j=jsonDecode(r.body) as Map<String,dynamic>;
  final result=(j['result']??j) as Map<String,dynamic>; return NavigationRoute(result['distanceM'] as int,result['durationS'] as int,(j['provider']??result['provider']) as String);
 }
}
