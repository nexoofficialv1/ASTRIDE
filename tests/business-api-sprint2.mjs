import assert from 'node:assert/strict';import {once} from 'node:events';import {server} from '../services/api/src/server.mjs';
server.listen(0);await once(server,'listening');const base=`http://127.0.0.1:${server.address().port}`;
const call=async(path,{method='GET',body}={})=>{const r=await fetch(base+path,{method,headers:{'content-type':'application/json'},body:body?JSON.stringify(body):undefined});return {status:r.status,data:await r.json()}};
try{
 let x=await call('/v1/fares/quote-v3',{method:'POST',body:{rideType:'FULL_TOTO',distanceKm:8,paymentPreference:'CASH',isOutsideArea:false,isNight:false}});assert.equal(x.status,200);assert.equal(x.data.quote.total,90);assert.equal(x.data.split.companyGross,5);
 x=await call('/v1/fares/quote-v3',{method:'POST',body:{rideType:'SHARE_TOTO',distanceKm:5,paymentPreference:'UPI',isOutsideArea:true}});assert.equal(x.status,422);assert.equal(x.data.error,'OUTSIDE_AREA_FULL_TOTO_ONLY');
 x=await call('/v1/fares/quote-v3',{method:'POST',body:{rideType:'SHARE_TOTO',distanceKm:4,paymentPreference:'UPI',isNight:true}});assert.equal(x.status,422);assert.equal(x.data.error,'SHARE_TOTO_UNAVAILABLE_AT_NIGHT');
 let p=await call('/v1/promoters',{method:'POST',body:{name:'P1',role:'PROMOTER'}});assert.equal(p.status,201);const pid=p.data.id;
 let d=await call('/v1/drivers/register',{method:'POST',body:{mobile:'9000000001',name:'Driver One',vehicle:{number:'WB41A0001'},bank:{upi:'d@upi'},emergencyContact:'9000000002'}});assert.equal(d.status,201);const did=d.data.id;
 x=await call('/v1/promoters/link-driver',{method:'POST',body:{promoterId:pid,driverId:did}});assert.equal(x.status,201);
 x=await call(`/v1/promoters/${pid}/drivers`);assert.equal(x.status,200);assert.equal(x.data.items.length,1);
 x=await call(`/v1/promoters/${pid}/coaching`,{method:'POST',body:{driverId:did,type:'ENCOURAGE',message:'Keep accepting rides'}});assert.equal(x.status,201);
 x=await call('/v1/late-arrival/evaluate',{method:'POST',body:{committedArrivalAt:'2026-07-11T10:00:00Z',actualArrivalAt:'2026-07-11T10:08:00Z'}});assert.equal(x.status,200);assert.equal(x.data.lateMinutes,5);assert.equal(x.data.penalty,10);
 console.log('Sprint 2 business API wiring passed');
}finally{server.close();}
