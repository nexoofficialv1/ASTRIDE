import assert from 'node:assert/strict';
import {once} from 'node:events';
import {server} from '../services/api/src/server.mjs';
server.listen(0,'127.0.0.1'); await once(server,'listening');
const base=`http://127.0.0.1:${server.address().port}`;
const call=async(path,method='GET',body,token)=>{const r=await fetch(base+path,{method,headers:{'content-type':'application/json',...(token?{authorization:`Bearer ${token}`}:{})},body:body===undefined?undefined:JSON.stringify(body)});return {status:r.status,data:await r.json()};};
try{
  let r=await call('/health'); assert.equal(r.status,200); assert.equal(r.data.version,'3.9.1-security-hotfix');
  const passengerCfg=(await call('/v1/mobile/config?app=passenger')).data; const driverCfg=(await call('/v1/mobile/config?app=driver')).data;
  assert.equal(passengerCfg.minimumAppVersion,'3.0.0'); assert.equal(driverCfg.minimumAppVersion,'3.0.0');
  r=await call('/v1/auth/otp/request','POST',{mobile:'9876500000'}); assert.equal(r.status,201);
  r=await call('/v1/auth/otp/verify','POST',{sessionId:r.data.sessionId,code:r.data.delivery.debugCode}); assert.equal(r.status,200); const passengerId=r.data.passenger.id;
  r=await call('/v1/drivers/register','POST',{mobile:'9000099999',fullName:'RC Driver',preferredLanguage:'hi',vehicle:{number:'WB-RC-100'}}); assert.equal(r.status,201); const driverId=r.data.id;
  for(const type of ['IDENTITY','PROFILE_PHOTO','VEHICLE_PHOTO','VEHICLE_REGISTRATION']) await call(`/v1/driver-profiles/${driverId}/documents`,'POST',{type,fileUrl:`https://files.invalid/${type}`});
  await call(`/v1/admin/drivers/${driverId}/review`,'POST',{status:'APPROVED'});
  await call(`/v1/driver-profiles/${driverId}/online`,'PUT',{online:true,location:{lat:23.2194,lng:88.3629}});
  const pickup={lat:23.2194,lng:88.3629},destination={lat:23.2400,lng:88.3500};
  r=await call('/v1/bookings','POST',{passengerId,pickup,destination,paymentMethod:'online',language:'bn'}); assert.equal(r.status,201); const bookingId=r.data.id;
  r=await call(`/v1/bookings/${bookingId}/match`,'POST',{}); assert.equal(r.data.booking.driverId,driverId);
  const payment=(await call('/v1/payments/orders','POST',{bookingId,passengerId,method:'online',idempotencyKey:'rc-e2e-1'})).data;
  r=await call(`/v1/payments/${payment.id}/verify`,'POST',{providerPaymentId:'rc-pay',signature:'valid'}); assert.equal(r.data.payment.status,'CAPTURED');
  const now=Date.now(); r=await call(`/v1/bookings/${bookingId}/tracking`,'POST',{actorType:'driver',actorId:driverId,samples:[{lat:23.22,lng:88.363,accuracyM:8,recordedAt:now}]}); assert.equal(r.status,201);
  for(const status of ['DRIVER_ARRIVING','DRIVER_ARRIVED','OTP_VERIFIED','IN_PROGRESS','COMPLETED']){r=await call(`/v1/bookings/${bookingId}/transition`,'POST',{status});assert.equal(r.data.status,status);}
  r=await call('/v1/safety/sos','POST',{actorType:'passenger',actorId:passengerId,bookingId,location:pickup,message:'RC test'}); assert.equal(r.status,201); const sosId=r.data.id;
  const login=await call('/v1/admin/auth/login','POST',{username:'admin',password:'admin123'}); const token=login.data.token;
  r=await call('/v1/admin/dashboard','GET',undefined,token); assert.equal(r.status,200); assert.ok(r.data.cards.completedRides>=1);
  r=await call(`/v1/admin/sos/${sosId}`,'PATCH',{status:'RESOLVED',notes:'RC resolved'},token); assert.equal(r.data.status,'RESOLVED');
  r=await call('/v1/admin/config','PATCH',{providers:{maps:{active:'google',fallback:'mappls'}},fare:{baseFare:25}},token); assert.equal(r.data.providers.maps.active,'google');
  r=await call('/v1/maps/route','POST',{origin:pickup,destination}); assert.equal(r.data.provider,'google');
  console.log('v1.0 release candidate end-to-end test passed');
} finally {await new Promise(resolve=>server.close(resolve));}
