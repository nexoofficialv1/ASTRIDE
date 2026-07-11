import crypto from 'node:crypto';
import {assertPaymentTransition} from '../domain/payment-machine.mjs';
const payments=new Map(),byBooking=new Map(),refunds=[],ledger=[],webhookEvents=new Map(),reconciliations=[];
const id=(p)=>`${p}_${crypto.randomUUID().slice(0,12)}`;
const now=()=>new Date().toISOString();
export function createPayment(input){if(byBooking.has(input.bookingId))return getPayment(byBooking.get(input.bookingId));const p={id:id('pay'),bookingId:input.bookingId,passengerId:input.passengerId,driverId:input.driverId||null,method:input.method,provider:input.provider,providerOrderId:input.providerOrderId||null,providerPaymentId:null,amountPaise:input.amountPaise,currency:input.currency||'INR',status:input.status||'CREATED',refundedPaise:0,idempotencyKey:input.idempotencyKey,createdAt:now(),updatedAt:now()};payments.set(p.id,p);byBooking.set(p.bookingId,p.id);ledger.push({id:id('led'),paymentId:p.id,type:'PAYMENT_CREATED',amountPaise:p.amountPaise,createdAt:now()});return structuredClone(p);}
export const getPayment=(paymentId)=>payments.has(paymentId)?structuredClone(payments.get(paymentId)):null;
export const getPaymentByBooking=(bookingId)=>byBooking.has(bookingId)?getPayment(byBooking.get(bookingId)):null;
export function updatePayment(paymentId,patch,event='PAYMENT_UPDATED'){const p=payments.get(paymentId);if(!p)return null;if(patch.status)assertPaymentTransition(p.status,patch.status);Object.assign(p,patch,{updatedAt:now()});ledger.push({id:id('led'),paymentId:p.id,type:event,amountPaise:patch.amountPaise??0,createdAt:now()});return structuredClone(p);}
export function addRefund(paymentId,amountPaise,reason){const p=payments.get(paymentId);if(!p)throw new Error('Payment not found');const available=p.amountPaise-p.refundedPaise;if(amountPaise<=0||amountPaise>available)throw new Error('Invalid refund amount');p.refundedPaise+=amountPaise;const status=p.refundedPaise===p.amountPaise?'REFUNDED':'PARTIALLY_REFUNDED';assertPaymentTransition(p.status,status);p.status=status;p.updatedAt=now();const r={id:id('ref'),paymentId,amountPaise,reason:reason||null,status:'PROCESSED',createdAt:now()};refunds.unshift(r);ledger.push({id:id('led'),paymentId:p.id,type:'REFUND',amountPaise:-amountPaise,createdAt:now()});return {payment:structuredClone(p),refund:structuredClone(r)};}
export const listRefunds=(paymentId)=>refunds.filter(r=>r.paymentId===paymentId).map(x=>structuredClone(x));
export const listPaymentLedger=(paymentId)=>ledger.filter(x=>x.paymentId===paymentId).map(x=>structuredClone(x));

export const listAllPayments=()=>[...payments.values()].map(x=>structuredClone(x));
export function findPaymentByProviderOrder(provider,providerOrderId){for(const p of payments.values())if(p.provider===provider&&p.providerOrderId===providerOrderId)return structuredClone(p);return null;}
export function findPaymentByProviderPayment(provider,providerPaymentId){for(const p of payments.values())if(p.provider===provider&&p.providerPaymentId===providerPaymentId)return structuredClone(p);return null;}
export function recordWebhookEvent({provider,eventId,eventType,verified,payloadHash,status='PROCESSED'}){const key=`${provider}:${eventId}`;if(webhookEvents.has(key))return {duplicate:true,event:structuredClone(webhookEvents.get(key))};const event={id:id('wh'),provider,eventId,eventType,verified:Boolean(verified),payloadHash,status,receivedAt:now()};webhookEvents.set(key,event);return {duplicate:false,event:structuredClone(event)};}
export const listWebhookEvents=()=>[...webhookEvents.values()].map(x=>structuredClone(x));
export function addReconciliation(input){const x={id:id('rec'),...input,createdAt:now()};reconciliations.unshift(x);return structuredClone(x);}
export const listReconciliations=()=>reconciliations.map(x=>structuredClone(x));

export function exportPaymentStoreState(){return {payments:[...payments.entries()],byBooking:[...byBooking.entries()],refunds:structuredClone(refunds),ledger:structuredClone(ledger),webhookEvents:[...webhookEvents.entries()],reconciliations:structuredClone(reconciliations)};}
export function restorePaymentStoreState(state={}){payments.clear();byBooking.clear();refunds.length=0;ledger.length=0;webhookEvents.clear();reconciliations.length=0;for(const [k,v] of state.payments||[])payments.set(k,v);for(const [k,v] of state.byBooking||[])byBooking.set(k,v);refunds.push(...(state.refunds||[]));ledger.push(...(state.ledger||[]));for(const [k,v] of state.webhookEvents||[])webhookEvents.set(k,v);reconciliations.push(...(state.reconciliations||[]));}
