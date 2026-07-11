class RuntimeConfig {
  const RuntimeConfig({required this.serviceEnabled,required this.maintenanceMode,required this.minimumVersion,required this.paymentMethods,required this.mapProvider});
  final bool serviceEnabled, maintenanceMode; final String minimumVersion,mapProvider; final List<String> paymentMethods;
  factory RuntimeConfig.fromJson(Map<String,dynamic> j)=>RuntimeConfig(
    serviceEnabled:j['serviceEnabled']!=false,maintenanceMode:j['maintenanceMode']==true,
    minimumVersion:(j['minimumVersion']??'1.0.0').toString(),mapProvider:(j['mapProvider']??'MAPPLS').toString(),
    paymentMethods:((j['paymentMethods']??['CASH']) as List).map((e)=>e.toString()).toList());
  static const fallback=RuntimeConfig(serviceEnabled:true,maintenanceMode:false,minimumVersion:'1.0.0',paymentMethods:['CASH'],mapProvider:'MAPPLS');
}
