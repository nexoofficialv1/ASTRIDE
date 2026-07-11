import assert from 'node:assert/strict';
import { once } from 'node:events';
import { server } from '../services/api/src/server.mjs';
server.listen(0,'127.0.0.1'); await once(server,'listening');
const port=server.address().port; const base=`http://127.0.0.1:${port}`;
const request=async(path,options={})=>{const r=await fetch(base+path,{headers:{'content-type':'application/json',...(options.headers||{})},...options});const body=await r.json();return {status:r.status,body};};
try{
  let r=await request('/health');assert.equal(r.body.version,'3.9.1-security-hotfix');
  r=await request('/v1/mobile/config?app=passenger');assert.equal(r.body.localeContentVersion,1);assert.equal(r.body.fare.currency,'INR');
  r=await request('/v1/auth/otp/request',{method:'POST',body:JSON.stringify({mobile:'9876543210'})});assert.equal(r.status,201);const sessionId=r.body.sessionId;const code=r.body.delivery.debugCode;
  r=await request('/v1/auth/otp/verify',{method:'POST',body:JSON.stringify({sessionId,code})});assert.equal(r.status,200);const passengerId=r.body.passenger.id;
  r=await request(`/v1/passengers/${passengerId}`,{method:'PATCH',body:JSON.stringify({fullName:'Demo Passenger',preferredLanguage:'bn'})});assert.equal(r.body.preferredLanguage,'bn');
  r=await request(`/v1/passengers/${passengerId}/places`,{method:'POST',body:JSON.stringify({label:'Home',address:'Kalna',location:{lat:23.2194,lng:88.3629}})});assert.equal(r.status,201);
  const pickup={lat:23.2194,lng:88.3629},destination={lat:23.2400,lng:88.3500};
  r=await request('/v1/fares/estimate',{method:'POST',body:JSON.stringify({pickup,destination})});assert.ok(r.body.amount>=30);const estimated=r.body.amount;
  await request('/v1/drivers/driver_1/availability',{method:'PUT',body:JSON.stringify({online:true,approved:true,rating:4.9,location:{lat:23.2200,lng:88.3630}})});
  r=await request('/v1/bookings',{method:'POST',body:JSON.stringify({passengerId,pickup,destination,language:'bn',paymentMethod:'cash'})});assert.equal(r.body.status,'SEARCHING');assert.equal(r.body.fareEstimate.amount,estimated);const bookingId=r.body.id;
  r=await request(`/v1/bookings/${bookingId}/match`,{method:'POST',body:'{}'});assert.equal(r.body.booking.status,'DRIVER_ASSIGNED');
  for(const status of ['DRIVER_ARRIVING','DRIVER_ARRIVED','OTP_VERIFIED','IN_PROGRESS','COMPLETED']){r=await request(`/v1/bookings/${bookingId}/transition`,{method:'POST',body:JSON.stringify({status})});assert.equal(r.body.status,status);}
  r=await request(`/v1/bookings/${bookingId}/rating`,{method:'POST',body:JSON.stringify({passengerId,score:5,comment:'Good ride'})});assert.equal(r.status,201);
  r=await request(`/v1/bookings/${bookingId}/complaints`,{method:'POST',body:JSON.stringify({passengerId,category:'GENERAL',description:'Test ticket'})});assert.equal(r.body.status,'OPEN');
  r=await request(`/v1/passengers/${passengerId}/bookings`);assert.equal(r.body.items.length,1);
  const login=await request('/v1/admin/auth/login',{method:'POST',body:JSON.stringify({username:'admin',password:'admin123'})});const adminToken=login.body.token;
  r=await request('/v1/admin/config',{method:'PATCH',headers:{authorization:`Bearer ${adminToken}`} ,body:JSON.stringify({fare:{baseFare:25,perKm:14},features:{onlinePayment:true}})});assert.equal(r.body.fare.baseFare,25);
  r=await request('/v1/mobile/config?app=passenger');assert.ok(r.body.capabilities.paymentMethods.includes('online'));
  console.log('v0.4 passenger experience smoke test passed');
} finally { server.close(); }
