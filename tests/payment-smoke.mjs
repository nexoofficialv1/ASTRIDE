import assert from 'node:assert/strict';import {once} from 'node:events';import {server} from '../services/api/src/server.mjs';
server.listen(0,'127.0.0.1');await once(server,'listening');const base=`http://127.0.0.1:${server.address().port}`;
const q=async(p,o={})=>{const r=await fetch(base+p,{headers:{'content-type':'application/json'},...o});return {status:r.status,body:await r.json()}};
try{
 let r=await q('/health');assert.equal(r.body.version,'3.9.1-security-hotfix');
 const pickup={lat:23.2194,lng:88.3629},destination={lat:23.24,lng:88.35};
 r=await q('/v1/bookings',{method:'POST',body:JSON.stringify({passengerId:'pay_p1',pickup,destination,paymentMethod:'online'})});assert.equal(r.status,201);const booking=r.body;
 r=await q('/v1/payments/orders',{method:'POST',body:JSON.stringify({bookingId:booking.id,passengerId:'pay_p1',method:'online',idempotencyKey:'idem-001'})});assert.equal(r.status,201);assert.equal(r.body.status,'PENDING');const paymentId=r.body.id;
 r=await q('/v1/payments/orders',{method:'POST',body:JSON.stringify({bookingId:booking.id,passengerId:'pay_p1',method:'online',idempotencyKey:'idem-001'})});assert.equal(r.status,200);assert.equal(r.body.id,paymentId);
 r=await q(`/v1/payments/${paymentId}/verify`,{method:'POST',body:JSON.stringify({providerPaymentId:'demo-pay',signature:'valid'})});assert.equal(r.status,200);assert.equal(r.body.payment.status,'CAPTURED');
 r=await q(`/v1/payments/${paymentId}/refunds`,{method:'POST',body:JSON.stringify({amountPaise:100,reason:'test partial refund'})});assert.equal(r.status,201);assert.equal(r.body.payment.status,'PARTIALLY_REFUNDED');
 r=await q(`/v1/payments/${paymentId}`);assert.equal(r.status,200);assert.equal(r.body.refunds.length,1);assert.ok(r.body.ledger.length>=3);
 const cashBooking=(await q('/v1/bookings',{method:'POST',body:JSON.stringify({passengerId:'pay_p2',pickup,destination,paymentMethod:'cash'})})).body;
 r=await q('/v1/payments/orders',{method:'POST',body:JSON.stringify({bookingId:cashBooking.id,passengerId:'pay_p2',method:'cash',idempotencyKey:'idem-cash-1'})});assert.equal(r.body.status,'CASH_DUE');
 r=await q(`/v1/payments/${r.body.id}/verify`,{method:'POST',body:JSON.stringify({collected:true})});assert.equal(r.body.payment.status,'CASH_COLLECTED');
 console.log('v0.7 payment engine smoke test passed');
}finally{server.close()}
