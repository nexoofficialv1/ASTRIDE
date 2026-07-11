import assert from 'node:assert/strict';
import fs from 'node:fs';
import { getMapAdapter } from '../services/api/src/providers/maps/index.mjs';
import { getPaymentAdapter } from '../services/api/src/providers/payments/index.mjs';
import { createOtp, verifyOtp } from '../services/api/src/store/passenger-store.mjs';

const origin={lat:23.2193,lng:88.3620},destination={lat:23.2320,lng:88.3540};
for(const name of ['mappls','google','osm']){const r=await getMapAdapter(name).route(origin,destination,'test');assert.equal(r.provider,name);assert.ok(r.distanceM>0);assert.ok(r.durationS>0);}
const order=await getPaymentAdapter('razorpay').createOrder(12500,'booking_s9','test');assert.equal(order.provider,'razorpay');assert.equal(order.amountPaise,12500);
const otp=createOtp('919876543210');assert.ok(otp.sessionId);assert.equal(verifyOtp(otp.sessionId,'000000'),null);assert.ok(verifyOtp(otp.sessionId,otp.code));
const push=fs.readFileSync(new URL('../services/api/src/providers/notifications/index.mjs',import.meta.url),'utf8');assert.match(push,/firebase\.messaging/);assert.match(push,/RS256/);
const maps=fs.readFileSync(new URL('../services/api/src/providers/maps/index.mjs',import.meta.url),'utf8');assert.match(maps,/routes\.googleapis\.com/);assert.match(maps,/apis\.mappls\.com/);
const payment=fs.readFileSync(new URL('../services/api/src/providers/payments/index.mjs',import.meta.url),'utf8');assert.match(payment,/api\.razorpay\.com\/v1\/orders/);
console.log('Sprint 9 integration contracts passed');
