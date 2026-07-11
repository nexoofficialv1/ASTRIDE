import assert from 'node:assert/strict';import {once} from 'node:events';import {server} from '../services/api/src/server.mjs';
server.listen(0);await once(server,'listening');const base=`http://127.0.0.1:${server.address().port}`;
const call=async(path,{method='GET',body,token}={})=>{const r=await fetch(base+path,{method,headers:{'content-type':'application/json',...(token?{'authorization':`Bearer ${token}`}:{})},body:body?JSON.stringify(body):undefined});return{status:r.status,data:await r.json()}};
try{
 let x=await call('/v1/promoters',{method:'POST',body:{name:'Area Lead',role:'AREA_PROMOTER',mobile:'9000010000',password:'StrongPass#1'}});assert.equal(x.status,201);const areaId=x.data.id;
 x=await call('/v1/promoters',{method:'POST',body:{name:'Local Partner',role:'PROMOTER',areaPromoterId:areaId,mobile:'9000010001',password:'StrongPass#2'}});assert.equal(x.status,201);const promoterId=x.data.id;
 const d=await call('/v1/drivers/register',{method:'POST',body:{mobile:'9000010002',name:'Partner Driver',vehicle:{number:'WB41Z1001'},bank:{upi:'p@upi'},emergencyContact:'9000010003'}});assert.equal(d.status,201);
 x=await call('/v1/promoters/link-driver',{method:'POST',body:{promoterId,areaPromoterId:areaId,driverId:d.data.id}});assert.equal(x.status,201);
 x=await call('/v1/partner/dashboard');assert.equal(x.status,401);
 x=await call('/v1/partner/auth/login',{method:'POST',body:{mobile:'9000010001',password:'wrong'}});assert.equal(x.status,401);
 x=await call('/v1/partner/auth/login',{method:'POST',body:{mobile:'9000010001',password:'StrongPass#2'}});assert.equal(x.status,200);const token=x.data.token;assert.equal(x.data.partner.role,'PROMOTER');
 x=await call('/v1/partner/me',{token});assert.equal(x.status,200);assert.equal(x.data.partner.id,promoterId);
 x=await call('/v1/partner/drivers',{token});assert.equal(x.status,200);assert.equal(x.data.items.length,1);assert.equal(x.data.items[0].driverId,d.data.id);
 x=await call('/v1/partner/coaching',{method:'POST',token,body:{driverId:d.data.id,type:'ENCOURAGE',message:'Complete more rides'}});assert.equal(x.status,201);
 x=await call('/v1/partner/earnings',{token});assert.equal(x.status,200);assert.equal(x.data.withdrawable,0);assert.ok(x.data.nextSettlementDate);
 x=await call('/v1/partner/withdrawals',{method:'POST',token,body:{amount:10}});assert.equal(x.status,422);assert.equal(x.data.error,'settlement_not_open_or_insufficient_balance');
 x=await call('/v1/partner/auth/logout',{method:'POST',token,body:{}});assert.equal(x.status,200);
 x=await call('/v1/partner/me',{token});assert.equal(x.status,401);
 console.log('Sprint 3 partner auth, scope, coaching and settlement gates passed');
}finally{server.close();}
