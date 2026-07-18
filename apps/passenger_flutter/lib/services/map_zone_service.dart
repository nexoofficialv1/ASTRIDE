import 'dart:convert';
import 'package:http/http.dart' as http;

class MapZoneContext {
  final bool outsideArea;
  final bool highRiskZone;
  final String? dynamicFareZone;
  final bool allowed;
  final String? reason;
  const MapZoneContext({required this.outsideArea,required this.highRiskZone,required this.dynamicFareZone,required this.allowed,this.reason});
  factory MapZoneContext.fromJson(Map<String,dynamic> json){
    final c=json['context'] as Map<String,dynamic>; final v=json['validation'] as Map<String,dynamic>;
    return MapZoneContext(outsideArea:c['isOutsideArea']==true,highRiskZone:c['highRiskZone']==true,dynamicFareZone:c['dynamicFareZone'] as String?,allowed:v['allowed']==true,reason:v['reason'] as String?);
  }
}
class MapZoneService {
  final String apiBaseUrl; final http.Client client;
  MapZoneService(this.apiBaseUrl,{http.Client? client}):client=client??http.Client();
  Future<MapZoneContext> evaluate({required double pickupLat,required double pickupLng,required double dropLat,required double dropLng,required String rideType,double? routeDistanceKm}) async {
    final response=await client.post(Uri.parse('$apiBaseUrl/v1/maps/context'),headers:{'content-type':'application/json'},body:jsonEncode({'pickup':{'lat':pickupLat,'lng':pickupLng},'destination':{'lat':dropLat,'lng':dropLng},'rideType':rideType,'distanceKm':routeDistanceKm}));
    if(response.statusCode!=200) throw StateError('Map zone evaluation failed (${response.statusCode})');
    return MapZoneContext.fromJson(jsonDecode(response.body) as Map<String,dynamic>);
  }
}
