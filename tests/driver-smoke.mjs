import assert from 'node:assert/strict';import {once} from 'node:events';import {server} from '../services/api/src/server.mjs';
server.listen(0,'127.0.0.1');await once(server,'listening');const base=`http://127.0.0.1:${server.address().port}`;
const q=async(p,o={})=>{const r=await fetch(base+p,{headers:{'content-type':'application/json'},...o});return {status:r.status,body:await r.json()}};
try{let r=await q('/health');assert.equal(r.body.version,'3.9.1-security-hotfix');r=await q('/v1/drivers/register',{method:'POST',body:JSON.stringify({mobile:'9000000001',fullName:'Demo Driver',preferredLanguage:'bn',vehicle:{number:'WB-TEST-1'}})});assert.equal(r.status,201);const id=r.body.id;
for(const type of ['IDENTITY','PROFILE_PHOTO','VEHICLE_PHOTO','VEHICLE_REGISTRATION']){r=await q(`/v1/driver-profiles/${id}/documents`,{method:'POST',body:JSON.stringify({type,fileUrl:`https://files/${type}`})});assert.equal(r.status,201)}
r=await q(`/v1/driver-profiles/${id}/readiness`);assert.equal(r.body.ready,true);
r=await q(`/v1/admin/drivers/${id}/review`,{method:'POST',body:JSON.stringify({status:'APPROVED'})});assert.equal(r.body.approved,true);
r=await q(`/v1/driver-profiles/${id}/online`,{method:'PUT',body:JSON.stringify({online:true,location:{lat:23.2194,lng:88.3629}})});assert.equal(r.body.online,true);
const pickup={lat:23.2194,lng:88.3629},destination={lat:23.24,lng:88.35};r=await q('/v1/bookings',{method:'POST',body:JSON.stringify({passengerId:'p1',pickup,destination,paymentMethod:'cash'})});const bid=r.body.id;r=await q(`/v1/bookings/${bid}/match`,{method:'POST',body:'{}'});assert.equal(r.body.booking.driverId,id);
for(const status of ['DRIVER_ARRIVING','DRIVER_ARRIVED','OTP_VERIFIED','IN_PROGRESS','COMPLETED'])await q(`/v1/bookings/${bid}/transition`,{method:'POST',body:JSON.stringify({status})});
r=await q(`/v1/driver-profiles/${id}/wallet`);assert.ok(r.body.balancePaise>0);const amount=Math.min(100,r.body.balancePaise);r=await q(`/v1/driver-profiles/${id}/settlements`,{method:'POST',body:JSON.stringify({amountPaise:amount})});assert.equal(r.status,201);console.log('v0.5 driver system smoke test passed');}finally{server.close()}
