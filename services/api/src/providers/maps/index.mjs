import { getProviderCredential } from '../../config/provider-vault.mjs';

const R=6371000; const rad=v=>v*Math.PI/180;
const distanceM=(a,b)=>{const dLat=rad(b.lat-a.lat),dLng=rad(b.lng-a.lng);const x=Math.sin(dLat/2)**2+Math.cos(rad(a.lat))*Math.cos(rad(b.lat))*Math.sin(dLng/2)**2;return Math.round(2*R*Math.asin(Math.sqrt(x))*1.22);};
const fallbackRoute=(provider,origin,destination)=>{const d=distanceM(origin,destination);return {provider,origin,destination,distanceM:d,durationS:Math.max(60,Math.round(d/(18_000/3600))),geometry:[origin,destination],estimated:true};};
async function fetchJson(url,options={}){const r=await fetch(url,options);if(!r.ok)throw new Error(`Map provider HTTP ${r.status}`);return r.json();}
const cred=(name,mode)=>getProviderCredential('maps',name,mode)||{};

const mappls={
 async geocode(query,mode='test'){
  const c=cred('mappls',mode); if(mode==='test'||!c.restApiKey)return {provider:'mappls',query,results:[]};
  const d=await fetchJson(`https://atlas.mappls.com/api/places/geocode?address=${encodeURIComponent(query)}&itemCount=10`,{headers:{Authorization:`bearer ${c.restApiKey}`}});
  return {provider:'mappls',query,results:(d.copResults||d.suggestedLocations||[]).map(x=>({label:x.formattedAddress||x.placeName,address:x.formattedAddress,lat:Number(x.latitude),lng:Number(x.longitude),providerId:x.eLoc||x.mapplsPin}))};
 },
 async route(origin,destination,mode='test'){
  const c=cred('mappls',mode); if(mode==='test'||!c.restApiKey)return fallbackRoute('mappls',origin,destination);
  const path=`${origin.lng},${origin.lat};${destination.lng},${destination.lat}`;
  const d=await fetchJson(`https://apis.mappls.com/advancedmaps/v1/${encodeURIComponent(c.restApiKey)}/route_adv/driving/${path}?geometries=geojson&overview=full`);
  const r=d.routes?.[0]; if(!r)throw new Error('Mappls route unavailable');
  return {provider:'mappls',origin,destination,distanceM:Math.round(r.distance),durationS:Math.round(r.duration),geometry:(r.geometry?.coordinates||[]).map(([lng,lat])=>({lat,lng})),estimated:false};
 }
};

const google={
 async geocode(query,mode='test'){
  const c=cred('google',mode); if(mode==='test'||!c.apiKey)return {provider:'google',query,results:[]};
  const d=await fetchJson(`https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(query)}&key=${encodeURIComponent(c.apiKey)}`);
  return {provider:'google',query,results:(d.results||[]).map(x=>({label:x.formatted_address,address:x.formatted_address,lat:x.geometry.location.lat,lng:x.geometry.location.lng,providerId:x.place_id}))};
 },
 async route(origin,destination,mode='test'){
  const c=cred('google',mode); if(mode==='test'||!c.apiKey)return fallbackRoute('google',origin,destination);
  const body={origin:{location:{latLng:{latitude:origin.lat,longitude:origin.lng}}},destination:{location:{latLng:{latitude:destination.lat,longitude:destination.lng}}},travelMode:'DRIVE',routingPreference:'TRAFFIC_AWARE',polylineQuality:'HIGH_QUALITY'};
  const d=await fetchJson('https://routes.googleapis.com/directions/v2:computeRoutes',{method:'POST',headers:{'content-type':'application/json','X-Goog-Api-Key':c.apiKey,'X-Goog-FieldMask':'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline'},body:JSON.stringify(body)});
  const r=d.routes?.[0]; if(!r)throw new Error('Google route unavailable');
  return {provider:'google',origin,destination,distanceM:r.distanceMeters,durationS:Number(String(r.duration||'0s').replace('s','')),encodedPolyline:r.polyline?.encodedPolyline,geometry:[origin,destination],estimated:false};
 }
};

const osm={
 async geocode(query,mode='test'){
  if(mode==='test')return {provider:'osm',query,results:[]};
  const d=await fetchJson(`https://nominatim.openstreetmap.org/search?format=jsonv2&limit=10&q=${encodeURIComponent(query)}`,{headers:{'user-agent':'ASTRIDE/3.6'}});
  return {provider:'osm',query,results:d.map(x=>({label:x.display_name,address:x.display_name,lat:Number(x.lat),lng:Number(x.lon),providerId:String(x.place_id)}))};
 },
 async route(origin,destination,mode='test'){
  if(mode==='test')return fallbackRoute('osm',origin,destination);
  const d=await fetchJson(`https://router.project-osrm.org/route/v1/driving/${origin.lng},${origin.lat};${destination.lng},${destination.lat}?overview=full&geometries=geojson`);
  const r=d.routes?.[0]; if(!r)throw new Error('OSM route unavailable');
  return {provider:'osm',origin,destination,distanceM:Math.round(r.distance),durationS:Math.round(r.duration),geometry:(r.geometry?.coordinates||[]).map(([lng,lat])=>({lat,lng})),estimated:false};
 }
};
const adapters={mappls,google,osm};
export function getMapAdapter(name){const adapter=adapters[name];if(!adapter)throw new Error(`Unsupported map provider: ${name}`);return adapter;}
