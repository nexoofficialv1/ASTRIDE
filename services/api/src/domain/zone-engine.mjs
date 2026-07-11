const R = 6371;
const rad = (v) => v * Math.PI / 180;
export function haversineKm(a,b){
  const dLat=rad(b.lat-a.lat), dLng=rad(b.lng-a.lng);
  const x=Math.sin(dLat/2)**2+Math.cos(rad(a.lat))*Math.cos(rad(b.lat))*Math.sin(dLng/2)**2;
  return 2*R*Math.asin(Math.sqrt(x));
}
export function pointInPolygon(point, polygon){
  if(!Array.isArray(polygon)||polygon.length<3) return false;
  let inside=false;
  for(let i=0,j=polygon.length-1;i<polygon.length;j=i++){
    const xi=polygon[i].lng, yi=polygon[i].lat, xj=polygon[j].lng, yj=polygon[j].lat;
    const intersect=((yi>point.lat)!==(yj>point.lat)) && (point.lng < (xj-xi)*(point.lat-yi)/((yj-yi)||Number.EPSILON)+xi);
    if(intersect) inside=!inside;
  }
  return inside;
}
export function evaluateZoneContext({pickup,destination,zones,now=new Date()}){
  const enabled=(zones||[]).filter(z=>z.enabled!==false);
  const pickupZones=enabled.filter(z=>pointInPolygon(pickup,z.polygon));
  const destinationZones=enabled.filter(z=>pointInPolygon(destination,z.polygon));
  const serviceZones=enabled.filter(z=>z.type==='SERVICE_AREA');
  const pickupInside=serviceZones.some(z=>pointInPolygon(pickup,z.polygon));
  const destinationInside=serviceZones.some(z=>pointInPolygon(destination,z.polygon));
  const highRisk=pickupZones.some(z=>z.type==='HIGH_RISK');
  const dynamic=pickupZones.find(z=>z.type==='DYNAMIC_FARE');
  return {
    pickupInsideServiceArea: pickupInside,
    destinationInsideServiceArea: destinationInside,
    isOutsideArea: pickupInside && !destinationInside,
    highRiskZone: highRisk,
    dynamicFareZone: dynamic?.code||null,
    pickupZoneCodes: pickupZones.map(z=>z.code),
    destinationZoneCodes: destinationZones.map(z=>z.code),
    evaluatedAt: now.toISOString(),
  };
}
export function validateRideAgainstZone({rideType,distanceKm,zoneContext,maximumTotoDistanceKm=29}){
  if(['FULL_TOTO','SHARE_TOTO'].includes(rideType)&&distanceKm>maximumTotoDistanceKm) return {allowed:false,reason:'TOTO_MAXIMUM_DISTANCE_EXCEEDED'};
  if(zoneContext.isOutsideArea&&rideType!=='FULL_TOTO') return {allowed:false,reason:'OUTSIDE_AREA_FULL_TOTO_ONLY'};
  return {allowed:true,reason:null};
}
