import assert from 'node:assert/strict';
process.env.NODE_ENV='test';
process.env.DATABASE_MODE='memory';
const {server}=await import('../services/api/src/server.mjs');
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const base=`http://127.0.0.1:${server.address().port}`;
const req=async(path,options={})=>{const r=await fetch(base+path,{...options,headers:{'content-type':'application/json',...(options.headers||{})}});let body={};try{body=await r.json();}catch{}return {status:r.status,body};};
try{
  let x=await req('/v1/bookings',{method:'POST',body:JSON.stringify({passengerId:'passenger_x',pickup:{lat:23.2,lng:88.3},destination:{lat:23.21,lng:88.31}})});
  assert.equal(x.status,401,'booking creation must require passenger auth');
  x=await req('/v1/auth/otp/request',{method:'POST',body:JSON.stringify({mobile:'919876543210'})});
  assert.equal(x.status,201); const code=x.body.delivery.debugCode; assert.ok(code);
  x=await req('/v1/auth/otp/verify',{method:'POST',body:JSON.stringify({sessionId:x.body.sessionId,code})});
  assert.equal(x.status,200); const passengerToken=x.body.accessToken; const passengerId=x.body.passenger.id;
  x=await req(`/v1/passengers/${passengerId}`,{headers:{authorization:`Bearer ${passengerToken}`}}); assert.equal(x.status,200);
  x=await req('/v1/passengers/passenger_910000000000',{headers:{authorization:`Bearer ${passengerToken}`}}); assert.equal(x.status,403);
  x=await req('/v1/drivers/register',{method:'POST',headers:{authorization:`Bearer ${passengerToken}`},body:JSON.stringify({mobile:'919876543210',fullName:'Test Driver'})});
  assert.equal(x.status,201); const driverToken=x.body.accessToken; const driverId=x.body.driver.id;
  x=await req(`/v1/driver-profiles/${driverId}`,{headers:{authorization:`Bearer ${driverToken}`}}); assert.equal(x.status,200);
  x=await req(`/v1/driver-profiles/${driverId}/wallet`); assert.equal(x.status,401);
  x=await req('/v1/notifications/send',{method:'POST',body:JSON.stringify({audience:'x',type:'x',payload:{}})}); assert.equal(x.status,401);
  x=await req('/v1/bookings',{method:'POST',headers:{authorization:`Bearer ${passengerToken}`},body:JSON.stringify({passengerId,pickup:{lat:23.2,lng:88.3},destination:{lat:23.21,lng:88.31}})}); assert.equal(x.status,201); const bookingId=x.body.id;
  x=await req(`/v1/bookings/${bookingId}`); assert.equal(x.status,403);
  x=await req(`/v1/bookings/${bookingId}`,{headers:{authorization:`Bearer ${passengerToken}`}}); assert.equal(x.status,200);
  console.log('security hardening v3.9.2 passed');
} finally {await new Promise(r=>server.close(r));}
