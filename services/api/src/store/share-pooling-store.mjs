import crypto from 'node:crypto';
import { canPoolBooking, buildDriverTimeline } from '../domain/share-pooling-engine.mjs';
const routes=new Map();const driverPermissions=new Map();const sessions=new Map();
const clone=x=>structuredClone(x);const now=()=>new Date().toISOString();

export function upsertShareRoute(input){
  if(!input.name||!Array.isArray(input.stops)||input.stops.length<2) throw new Error('Share route requires a name and at least two stops');
  const id=input.id||crypto.randomUUID();
  const seen=new Set();
  const stops=input.stops.map((s,index)=>{const sid=s.id||crypto.randomUUID();if(seen.has(sid))throw new Error('Duplicate stop id');seen.add(sid);if(typeof s.lat!=='number'||typeof s.lng!=='number')throw new Error('Invalid stop coordinates');return {id:sid,name:s.name||`Stop ${index+1}`,lat:s.lat,lng:s.lng,zoneId:s.zoneId||null,sequenceNo:Number(s.sequenceNo||index+1),enabled:s.enabled!==false};}).sort((a,b)=>a.sequenceNo-b.sequenceNo);
  const route={id,code:input.code||`SHARE_${id.slice(0,8).toUpperCase()}`,name:input.name,enabled:input.enabled!==false,defaultCapacity:Number(input.defaultCapacity||4),allowedZoneIds:[...new Set(input.allowedZoneIds||stops.map(s=>s.zoneId).filter(Boolean))],corridorGeoJson:input.corridorGeoJson||null,stops,createdAt:routes.get(id)?.createdAt||now(),updatedAt:now()};
  routes.set(id,route);return clone(route);
}
export const listShareRoutes=()=>[...routes.values()].map(clone);
export const getShareRoute=id=>routes.has(id)?clone(routes.get(id)):null;
export const removeShareRoute=id=>routes.delete(id);

export function setDriverSharePermissions(driverId,input){
  const item={driverId,routeIds:[...new Set(input.routeIds||[])],zoneIds:[...new Set(input.zoneIds||[])],serviceTypes:[...new Set(input.serviceTypes||['SHARE_TOTO','FULL_TOTO'])],primaryZoneId:input.primaryZoneId||null,capacity:Number(input.capacity||4),validFrom:input.validFrom||null,validUntil:input.validUntil||null,active:input.active!==false,updatedAt:now()};
  driverPermissions.set(driverId,item);return clone(item);
}
export const getDriverSharePermissions=driverId=>driverPermissions.has(driverId)?clone(driverPermissions.get(driverId)):null;
export function driverCanOperateShareRoute(driverId,routeId,at=new Date()){
  const p=driverPermissions.get(driverId);if(!p||!p.active||!p.serviceTypes.includes('SHARE_TOTO')||!p.routeIds.includes(routeId))return false;
  if(p.validFrom&&at<new Date(p.validFrom))return false;if(p.validUntil&&at>new Date(p.validUntil))return false;return true;
}

export function findOpenShareSession({driverId,routeId,direction}){
  return clone([...sessions.values()].find(s=>s.driverId===driverId&&s.routeId===routeId&&s.direction===direction&&['BOARDING','IN_PROGRESS'].includes(s.status))||null);
}
export function createShareSession({driverId,routeId,direction='FORWARD',capacity=4}){
  if(!driverCanOperateShareRoute(driverId,routeId)) throw new Error('Driver is not permitted for this share route');
  const session={id:crypto.randomUUID(),driverId,routeId,direction,capacity:Number(capacity),status:'BOARDING',bookings:[],createdAt:now(),updatedAt:now()};sessions.set(session.id,session);return clone(session);
}
export const getShareSession=id=>sessions.has(id)?clone(sessions.get(id)):null;
export const listShareSessions=()=>[...sessions.values()].map(clone);
export function addBookingToShareSession(sessionId,{route,bookingId,passengerId,pickupStopId,dropStopId,seats=1}){
  const session=sessions.get(sessionId);if(!session)throw new Error('Share session not found');
  if(session.bookings.some(x=>x.bookingId===bookingId))return clone(session);
  const check=canPoolBooking({route,session,pickupStopId,dropStopId,seats,direction:session.direction,capacity:session.capacity});if(!check.valid){const e=new Error(check.reason);e.details=check;throw e;}
  session.bookings.push({bookingId,passengerId,pickupStopId,dropStopId,seats:Number(seats),segmentKeys:check.segmentKeys,status:'CONFIRMED',createdAt:now()});session.updatedAt=now();return clone(session);
}
export function updateShareBookingStatus(sessionId,bookingId,status){const s=sessions.get(sessionId);if(!s)return null;const b=s.bookings.find(x=>x.bookingId===bookingId);if(!b)return null;b.status=status;b.updatedAt=now();s.updatedAt=now();return clone(s);}
export function updateShareSession(sessionId,patch){const s=sessions.get(sessionId);if(!s)return null;Object.assign(s,patch,{id:s.id,updatedAt:now()});return clone(s);}
export function getShareTimeline(sessionId){const s=sessions.get(sessionId);if(!s)return null;const r=routes.get(s.routeId);return {session:clone(s),timeline:buildDriverTimeline(r,s)};}

export function exportSharePoolingState(){return {routes:[...routes.entries()],driverPermissions:[...driverPermissions.entries()],sessions:[...sessions.entries()]};}
export function restoreSharePoolingState(state={}){routes.clear();driverPermissions.clear();sessions.clear();for(const [k,v] of state.routes||[])routes.set(k,v);for(const [k,v] of state.driverPermissions||[])driverPermissions.set(k,v);for(const [k,v] of state.sessions||[])sessions.set(k,v);}
