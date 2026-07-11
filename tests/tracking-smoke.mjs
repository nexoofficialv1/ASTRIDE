import assert from 'node:assert/strict';
import { server } from '../services/api/src/server.mjs';
const listen = () => new Promise(r => server.listen(0,'127.0.0.1',()=>r(server.address().port)));
const close = () => new Promise(r => server.close(r));
const req = async (port,path,method='GET',body) => { const res=await fetch(`http://127.0.0.1:${port}${path}`,{method,headers:{'content-type':'application/json'},body:body?JSON.stringify(body):undefined}); return {status:res.status,data:await res.json()}; };
const port=await listen();
try {
  const health=await req(port,'/health'); assert.equal(health.data.version,'3.9.1-security-hotfix');
  const config=await req(port,'/v1/mobile/config?app=driver'); assert.equal(config.data.tracking.enabled,true); assert.equal(config.data.tracking.updateIntervalSeconds,5);
  const booking=await req(port,'/v1/bookings','POST',{passengerId:'p1',pickup:{lat:23.22,lng:88.36},destination:{lat:23.24,lng:88.38}}); assert.equal(booking.status,201);
  const id=booking.data.id;
  const now=Date.now();
  const track=await req(port,`/v1/bookings/${id}/tracking`,'POST',{actorType:'driver',actorId:'d1',samples:[{lat:23.2201,lng:88.3601,accuracyM:12,recordedAt:now},{lat:23.2202,lng:88.3602,accuracyM:10,recordedAt:now+5000}]});
  assert.equal(track.status,201); assert.equal(track.data.accepted,2); assert.equal(track.data.snapshot.points,2);
  const live=await req(port,'/v1/drivers/d1/live-location'); assert.equal(live.status,200); assert.equal(live.data.lat,23.2202);
  const bad=await req(port,`/v1/bookings/${id}/tracking`,'POST',{actorType:'driver',actorId:'d1',samples:[{lat:99,lng:88,accuracyM:5,recordedAt:now+10000}]}); assert.equal(bad.status,400);
  const route=await req(port,'/v1/maps/route','POST',{origin:{lat:23.22,lng:88.36},destination:{lat:23.24,lng:88.38}}); assert.equal(route.status,200); assert.equal(route.data.provider,'mappls');
  const queued=await req(port,'/v1/tracking/offline-queue','POST',{deviceId:'dev1',samples:[{x:1},{x:2}]}); assert.equal(queued.data.totalQueued,2);
  const flushed=await req(port,'/v1/tracking/offline-flush','POST',{deviceId:'dev1'}); assert.equal(flushed.data.samples.length,2);
  console.log('v0.6 tracking smoke test passed');
} finally { await close(); }
