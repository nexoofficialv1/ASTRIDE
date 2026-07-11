export function normalizeDirection(value){
  const direction=String(value||'FORWARD').toUpperCase();
  if(!['FORWARD','REVERSE'].includes(direction)) throw new Error('Invalid route direction');
  return direction;
}

export function orderedStops(route,direction='FORWARD'){
  const stops=[...(route?.stops||[])].sort((a,b)=>a.sequenceNo-b.sequenceNo);
  return normalizeDirection(direction)==='REVERSE'?stops.reverse():stops;
}

export function resolveJourney(route,pickupStopId,dropStopId,direction='FORWARD'){
  const stops=orderedStops(route,direction);
  const pickupIndex=stops.findIndex(s=>s.id===pickupStopId);
  const dropIndex=stops.findIndex(s=>s.id===dropStopId);
  if(pickupIndex<0||dropIndex<0) return {valid:false,reason:'STOP_NOT_ON_ROUTE'};
  if(dropIndex<=pickupIndex) return {valid:false,reason:'WRONG_DIRECTION'};
  return {valid:true,pickupIndex,dropIndex,stops,segmentKeys:stops.slice(pickupIndex,dropIndex).map((s,i)=>`${s.id}->${stops[pickupIndex+i+1].id}`)};
}

export function segmentOccupancy(session){
  const occupancy={};
  for(const booking of session?.bookings||[]){
    if(['CANCELLED','REJECTED','NO_SHOW','COMPLETED'].includes(booking.status)) continue;
    for(const key of booking.segmentKeys||[]) occupancy[key]=(occupancy[key]||0)+Number(booking.seats||1);
  }
  return occupancy;
}

export function canPoolBooking({route,session,pickupStopId,dropStopId,seats=1,direction='FORWARD',capacity}){
  const journey=resolveJourney(route,pickupStopId,dropStopId,direction);
  if(!journey.valid) return journey;
  const requestedSeats=Number(seats);
  const maxSeats=Number(capacity||session?.capacity||route?.defaultCapacity||4);
  if(!Number.isInteger(requestedSeats)||requestedSeats<1) return {valid:false,reason:'INVALID_SEAT_COUNT'};
  const occupancy=segmentOccupancy(session||{bookings:[]});
  const blocked=journey.segmentKeys.find(key=>(occupancy[key]||0)+requestedSeats>maxSeats);
  if(blocked) return {valid:false,reason:'SEGMENT_CAPACITY_EXCEEDED',segment:blocked,occupancy:occupancy[blocked]||0,capacity:maxSeats};
  return {...journey,valid:true,seats:requestedSeats,capacity:maxSeats,occupancy};
}

export function buildDriverTimeline(route,session){
  const stops=orderedStops(route,session.direction);
  return stops.map((stop,index)=>{
    const pickups=[];const drops=[];
    for(const booking of session.bookings||[]){
      if(['CANCELLED','REJECTED','NO_SHOW'].includes(booking.status)) continue;
      if(booking.pickupStopId===stop.id) pickups.push({bookingId:booking.bookingId,passengerId:booking.passengerId,seats:booking.seats,status:booking.status});
      if(booking.dropStopId===stop.id) drops.push({bookingId:booking.bookingId,passengerId:booking.passengerId,seats:booking.seats,status:booking.status});
    }
    return {sequence:index+1,stopId:stop.id,name:stop.name,lat:stop.lat,lng:stop.lng,pickups,drops,pickupSeats:pickups.reduce((n,x)=>n+x.seats,0),dropSeats:drops.reduce((n,x)=>n+x.seats,0)};
  }).filter(x=>x.pickups.length||x.drops.length);
}

export function nearestRouteStop(route,point,maxDistanceM=500){
  const toRad=v=>v*Math.PI/180;const earth=6371000;
  const distance=(a,b)=>{const dLat=toRad(b.lat-a.lat),dLng=toRad(b.lng-a.lng);const q=Math.sin(dLat/2)**2+Math.cos(toRad(a.lat))*Math.cos(toRad(b.lat))*Math.sin(dLng/2)**2;return 2*earth*Math.asin(Math.sqrt(q));};
  const ranked=(route?.stops||[]).map(stop=>({...stop,distanceM:distance(point,stop)})).sort((a,b)=>a.distanceM-b.distanceM);
  return ranked[0]&&ranked[0].distanceM<=maxDistanceM?ranked[0]:null;
}
