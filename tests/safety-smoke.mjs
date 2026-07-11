import assert from 'node:assert/strict';
import { server } from '../services/api/src/server.mjs';
await new Promise(r=>server.listen(0,'127.0.0.1',r)); const base=`http://127.0.0.1:${server.address().port}`;
const call=async(path,method='GET',body,token)=>{const r=await fetch(base+path,{method,headers:{'content-type':'application/json',...(token?{authorization:`Bearer ${token}`}:{})},body:body?JSON.stringify(body):undefined});return {status:r.status,data:await r.json()};};
try{
 let r=await call('/health'); assert.equal(r.data.version,'3.9.1-security-hotfix');
 r=await call('/v1/safety/sos','POST',{actorType:'passenger',actorId:'p1',bookingId:'b1',location:{lat:23.22,lng:88.36},message:'Help'}); assert.equal(r.status,201); assert.equal(r.data.status,'OPEN'); const sosId=r.data.id;
 r=await call('/v1/safety/route-deviation','POST',{bookingId:'b1',expectedDistanceM:1000,actualDistanceM:1700}); assert.equal(r.data.alert,true);
 r=await call('/v1/notifications/send','POST',{audience:'passenger:p1',type:'RIDE_UPDATE',payload:{status:'DRIVER_ASSIGNED'}}); assert.equal(r.data.status,'SENT');
 const login=await call('/v1/admin/auth/login','POST',{username:'admin',password:'admin123'}); const token=login.data.token;
 r=await call('/v1/admin/sos','GET',null,token); assert.equal(r.data.items.length,1);
 r=await call(`/v1/admin/sos/${sosId}`,'PATCH',{status:'RESOLVED',notes:'Handled'},token); assert.equal(r.data.status,'RESOLVED');
 r=await call('/v1/admin/risk-events','GET',null,token); assert.ok(r.data.items.some(x=>x.type==='SOS_TRIGGERED')); assert.ok(r.data.items.some(x=>x.type==='ROUTE_DEVIATION'));
 console.log('v0.9 safety/security smoke test passed');
} finally {await new Promise(r=>server.close(r));}
