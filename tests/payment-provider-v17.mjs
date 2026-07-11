import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import {server} from '../services/api/src/server.mjs';
const listen=()=>new Promise(r=>server.listen(0,'127.0.0.1',()=>r(server.address().port)));
const req=async(port,path,{method='GET',body,token,headers={}}={})=>{const res=await fetch(`http://127.0.0.1:${port}${path}`,{method,headers:{'content-type':'application/json',...(token?{authorization:`Bearer ${token}`}:{ }),...headers},body:body===undefined?undefined:JSON.stringify(body)});return {status:res.status,data:await res.json()};};
const port=await listen();
try{
 const login=await req(port,'/v1/admin/auth/login',{method:'POST',body:{username:'admin',password:'admin123'}}); assert.equal(login.status,200); const token=login.data.token;
 const secret='whsec_test_123';
 let r=await req(port,'/v1/admin/providers/credentials',{method:'PUT',token,body:{type:'payments',name:'razorpay',mode:'test',credentials:{keyId:'rzp_test',keySecret:'key_secret',webhookSecret:secret}}}); assert.equal(r.status,200);
 r=await req(port,'/v1/admin/providers/test',{method:'POST',token,body:{type:'payments',name:'razorpay',mode:'test'}}); assert.equal(r.status,200); assert.equal(r.data.provider,'razorpay');
 const passenger=await req(port,'/v1/auth/otp/request',{method:'POST',body:{mobile:'919999001177'}}); const verify=await req(port,'/v1/auth/otp/verify',{method:'POST',body:{sessionId:passenger.data.sessionId,code:passenger.data.delivery.debugCode}}); const passengerId=verify.data.passenger.id;
 const booking=await req(port,'/v1/bookings',{method:'POST',body:{passengerId,pickup:{lat:23.2,lng:88.3,address:'A'},destination:{lat:23.21,lng:88.31,address:'B'},paymentMethod:'online'}}); assert.equal(booking.status,201);
 const order=await req(port,'/v1/payments/orders',{method:'POST',body:{bookingId:booking.data.id,passengerId,method:'online',idempotencyKey:'v17-key',amountPaise:100}}); assert.equal(order.status,201);
 const event={event:'payment.captured',payload:{payment:{entity:{id:'pay_live_1',order_id:order.data.providerOrderId}}}}; const raw=JSON.stringify(event); const signature=crypto.createHmac('sha256',secret).update(raw).digest('hex');
 const webhook=await fetch(`http://127.0.0.1:${port}/v1/payments/webhooks/razorpay`,{method:'POST',headers:{'content-type':'application/json','x-razorpay-signature':signature,'x-razorpay-event-id':'evt_1'},body:raw}); assert.equal(webhook.status,200);
 const duplicate=await fetch(`http://127.0.0.1:${port}/v1/payments/webhooks/razorpay`,{method:'POST',headers:{'content-type':'application/json','x-razorpay-signature':signature,'x-razorpay-event-id':'evt_1'},body:raw}); const dup=await duplicate.json(); assert.equal(dup.duplicate,true);
 const payment=await req(port,`/v1/payments/${order.data.id}`); assert.equal(payment.data.status,'CAPTURED');
 const recon=await req(port,'/v1/admin/payments/reconcile',{method:'POST',token,body:{paymentId:order.data.id}}); assert.equal(recon.status,200); assert.equal(recon.data.items.length,1); assert.equal(recon.data.items[0].matched,true);
 console.log('v1.7 payment provider/webhook/reconciliation test passed');
} finally {await new Promise(r=>server.close(r));}
