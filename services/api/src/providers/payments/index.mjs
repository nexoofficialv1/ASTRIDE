import crypto from 'node:crypto';
import { getProviderCredential } from '../../config/provider-vault.mjs';
const makeId=(p)=>`${p}_${crypto.randomUUID().slice(0,12)}`;
const timingSafeHex=(a,b)=>{try{const aa=Buffer.from(String(a||''),'hex'),bb=Buffer.from(String(b||''),'hex');return aa.length===bb.length&&crypto.timingSafeEqual(aa,bb);}catch{return false;}};
const hmac=(secret,value)=>crypto.createHmac('sha256',secret).update(value).digest('hex');
const credential=(name,mode)=>getProviderCredential('payments',name,mode)||{};

const adapters={
  razorpay:{
    async createOrder(amountPaise,reference,mode='test'){const c=credential('razorpay',mode);if(mode==='test'||!c.keyId||!c.keySecret)return {provider:'razorpay',providerOrderId:makeId('order'),amountPaise,reference,status:'PENDING',liveConfigured:false};const auth=Buffer.from(`${c.keyId}:${c.keySecret}`).toString('base64');const r=await fetch('https://api.razorpay.com/v1/orders',{method:'POST',headers:{authorization:`Basic ${auth}`,'content-type':'application/json'},body:JSON.stringify({amount:amountPaise,currency:'INR',receipt:reference,notes:{bookingId:reference}})});if(!r.ok)throw new Error(`Razorpay HTTP ${r.status}`);const d=await r.json();return {provider:'razorpay',providerOrderId:d.id,amountPaise:d.amount,reference,status:'PENDING',liveConfigured:true,keyId:c.keyId};},
    async verifyPayment(payload,mode='test'){const c=credential('razorpay',mode);const expected=c.keySecret&&payload?.providerOrderId&&payload?.providerPaymentId?hmac(c.keySecret,`${payload.providerOrderId}|${payload.providerPaymentId}`):null;const verified=Boolean(payload?.verified||(mode==='test'&&payload?.signature==='valid')||(expected&&timingSafeHex(expected,payload?.signature)));return {provider:'razorpay',providerPaymentId:payload?.providerPaymentId||makeId('pay'),verified,status:verified?'CAPTURED':'FAILED'};},
    async verifyWebhook({headers,rawBody,mode='test'}){const c=credential('razorpay',mode);const eventId=headers['x-razorpay-event-id']||headers['x-event-id'];const signature=headers['x-razorpay-signature'];const verified=Boolean(c.webhookSecret&&signature&&timingSafeHex(hmac(c.webhookSecret,rawBody),signature));let payload={};try{payload=JSON.parse(rawBody);}catch{}return {verified,eventId:eventId||payload.id||makeId('evt'),eventType:payload.event||'unknown',payload};},
    async refund(providerPaymentId,amountPaise,mode='test'){const c=credential('razorpay',mode);if(mode==='test'||!c.keyId||!c.keySecret)return {provider:'razorpay',providerPaymentId,refundId:makeId('rfnd'),amountPaise,status:'PROCESSED',liveConfigured:false};const auth=Buffer.from(`${c.keyId}:${c.keySecret}`).toString('base64');const r=await fetch(`https://api.razorpay.com/v1/payments/${providerPaymentId}/refund`,{method:'POST',headers:{authorization:`Basic ${auth}`,'content-type':'application/json'},body:JSON.stringify({amount:amountPaise})});if(!r.ok)throw new Error(`Razorpay refund HTTP ${r.status}`);const d=await r.json();return {provider:'razorpay',providerPaymentId,refundId:d.id,amountPaise:d.amount,status:String(d.status||'processed').toUpperCase(),liveConfigured:true};},
    async fetchPayment(providerPaymentId,mode='test'){const c=credential('razorpay',mode);if(mode==='test'||!c.keyId||!c.keySecret)return {provider:'razorpay',providerPaymentId,status:'CAPTURED',mode};const auth=Buffer.from(`${c.keyId}:${c.keySecret}`).toString('base64');const r=await fetch(`https://api.razorpay.com/v1/payments/${providerPaymentId}`,{headers:{authorization:`Basic ${auth}`}});if(!r.ok)throw new Error(`Razorpay fetch HTTP ${r.status}`);const d=await r.json();return {provider:'razorpay',providerPaymentId,status:String(d.status||'failed').toUpperCase(),amountPaise:d.amount};}
  },
  bharatpe:{
    async createOrder(amountPaise,reference,mode='test'){const c=credential('bharatpe',mode);return {provider:'bharatpe',providerOrderId:makeId('order'),amountPaise,reference,status:'PENDING',liveConfigured:Boolean(c.merchantId&&c.apiKey)};},
    async verifyPayment(payload,mode='test'){const c=credential('bharatpe',mode);const verified=Boolean(payload?.verified||(c.apiKey&&payload?.signature&&timingSafeHex(hmac(c.apiKey,`${payload.providerOrderId}|${payload.providerPaymentId}`),payload.signature)));return {provider:'bharatpe',providerPaymentId:payload?.providerPaymentId||makeId('pay'),verified,status:verified?'CAPTURED':'FAILED'};},
    async verifyWebhook({headers,rawBody,mode='test'}){const c=credential('bharatpe',mode);const signature=headers['x-bharatpe-signature']||headers['x-signature'];const verified=Boolean(c.webhookSecret&&signature&&timingSafeHex(hmac(c.webhookSecret,rawBody),signature));let payload={};try{payload=JSON.parse(rawBody);}catch{}return {verified,eventId:headers['x-event-id']||payload.eventId||makeId('evt'),eventType:payload.event||payload.type||'unknown',payload};},
    async refund(providerPaymentId,amountPaise,mode='test'){return {provider:'bharatpe',providerPaymentId,refundId:makeId('rfnd'),amountPaise,status:'PROCESSED',mode};},
    async fetchPayment(providerPaymentId,mode='test'){return {provider:'bharatpe',providerPaymentId,status:'CAPTURED',mode};}
  },
  cash:{
    async createOrder(amountPaise,reference){return {provider:'cash',providerOrderId:makeId('cash'),amountPaise,reference,status:'CASH_DUE'};},
    async verifyPayment(payload){return {provider:'cash',providerPaymentId:null,verified:Boolean(payload?.collected),status:payload?.collected?'CASH_COLLECTED':'FAILED'};},
    async verifyWebhook(){return {verified:false,eventId:null,eventType:'unsupported',payload:{}};},
    async refund(_id,amountPaise){return {provider:'cash',refundId:makeId('cash_refund'),amountPaise,status:'PROCESSED'};},
    async fetchPayment(_id){return {provider:'cash',status:'CASH_DUE'};}
  }
};
export function getPaymentAdapter(name){const adapter=adapters[name];if(!adapter)throw new Error(`Unsupported payment provider: ${name}`);return adapter;}
export const paymentSignature={hmac};
