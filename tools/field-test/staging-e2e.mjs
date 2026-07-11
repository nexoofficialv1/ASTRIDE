#!/usr/bin/env node
import fs from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const baseUrl=(process.env.ASTRIDE_BASE_URL||'http://127.0.0.1:3333').replace(/\/$/,'');
const mobile=process.env.FIELD_TEST_MOBILE||'9876543210';
const suppliedOtp=process.env.FIELD_TEST_OTP_CODE||'';
const allowMutating=process.env.ALLOW_MUTATING_FIELD_TEST==='true';
const allowProduction=process.env.ALLOW_PRODUCTION_FIELD_TEST==='true';
const allowNonReady=process.env.ALLOW_NON_READY_FIELD_TEST==='true';
const paymentMode=(process.env.FIELD_TEST_PAYMENT_MODE||'cash').toLowerCase();
const outputDir=process.env.FIELD_TEST_OUTPUT_DIR||'field-test-results';
const isProduction=/\b(api\.)?astride\b|production/i.test(baseUrl) && !/staging|stage|test|localhost|127\.0\.0\.1/i.test(baseUrl);
if(isProduction&&!allowProduction) throw new Error('Production field test blocked. Set ALLOW_PRODUCTION_FIELD_TEST=true only after approval.');
if(!allowMutating) throw new Error('Mutating field test blocked. Set ALLOW_MUTATING_FIELD_TEST=true for an approved staging run.');
if(!['cash','online'].includes(paymentMode)) throw new Error('FIELD_TEST_PAYMENT_MODE must be cash or online');

const report={startedAt:new Date().toISOString(),baseUrl,mobileMasked:`***${mobile.slice(-4)}`,paymentMode,steps:[],passed:false};
const remember=(name,status,detail={})=>{report.steps.push({name,status,at:new Date().toISOString(),...detail});};
const request=async(route,options={})=>{
  const acceptedStatuses=options.acceptedStatuses||[];
  const fetchOptions={...options}; delete fetchOptions.acceptedStatuses;
  const started=Date.now();
  const response=await fetch(baseUrl+route,{...fetchOptions,headers:{'content-type':'application/json','x-astride-field-test':'sprint10c',...(fetchOptions.headers||{})}});
  const raw=await response.text(); let body; try{body=raw?JSON.parse(raw):{};}catch{body={raw};}
  if(!response.ok&&!acceptedStatuses.includes(response.status)) throw new Error(`${options.method||'GET'} ${route} -> ${response.status}: ${JSON.stringify(body)}`);
  return {status:response.status,body,durationMs:Date.now()-started};
};
const step=async(name,fn)=>{try{const out=await fn();remember(name,'PASS',{durationMs:out?.durationMs,summary:out?.summary});return out;}catch(error){remember(name,'FAIL',{error:error.message});throw error;}};

let serverProcess=null;
try{
  const health=await step('health',async()=>{const r=await request('/health');if(!r.body.ok)throw new Error('health.ok is false');return {...r,summary:r.body.version};});
  await step('readiness',async()=>{const r=await request('/ready',{acceptedStatuses:allowNonReady?[503]:[]});if(!r.body.ok&&!allowNonReady)throw new Error('staging is not ready');return {...r,summary:r.body.ok?'ready':'LOCAL OVERRIDE: non-ready dependencies reported'};});
  const otpRequest=await step('otp_request',async()=>{const r=await request('/v1/auth/otp/request',{method:'POST',body:JSON.stringify({mobile})});return {...r,summary:r.body.delivery?.provider||'unknown'};});
  const otpCode=suppliedOtp||otpRequest.body.delivery?.debugCode;
  if(!otpCode) throw new Error('Live OTP code required in FIELD_TEST_OTP_CODE');
  const auth=await step('otp_verify',async()=>{const r=await request('/v1/auth/otp/verify',{method:'POST',body:JSON.stringify({sessionId:otpRequest.body.sessionId,code:otpCode})});return {...r,summary:r.body.passenger?.id};});
  const passengerId=auth.body.passenger.id;
  const runId=Date.now(); const driverId=`field_driver_${runId}`;
  const pickup={lat:23.2194,lng:88.3629}; const destination={lat:23.2400,lng:88.3500};
  await step('driver_online',async()=>request(`/v1/drivers/${driverId}/availability`,{method:'PUT',body:JSON.stringify({online:true,approved:true,rating:4.9,location:{lat:23.2198,lng:88.3632}})}));
  const booking=await step('booking_create',async()=>{const r=await request('/v1/bookings',{method:'POST',body:JSON.stringify({passengerId,pickup,destination,pickupAddress:'Kalna field-test pickup',destinationAddress:'Kalna field-test destination',language:'bn',paymentMethod:paymentMode,paymentPreference:paymentMode==='cash'?'CASH':'ONLINE'})});return {...r,summary:r.body.id};});
  const bookingId=booking.body.id;
  const matched=await step('driver_match',async()=>{const r=await request(`/v1/bookings/${bookingId}/match`,{method:'POST',body:'{}'});if(r.body.booking?.driverId!==driverId)throw new Error('Expected field-test driver was not assigned');return {...r,summary:r.body.booking.status};});
  for(const status of ['DRIVER_ARRIVING','DRIVER_ARRIVED']) await step(`ride_${status.toLowerCase()}`,async()=>request(`/v1/bookings/${bookingId}/transition`,{method:'POST',body:JSON.stringify({status})}));
  await step('device_register',async()=>request('/v1/devices/register',{method:'POST',body:JSON.stringify({actorType:'DRIVER',actorId:driverId,deviceId:`field-device-${runId}`,platform:'android',pushToken:`field-token-${runId}`})}));
  await step('push_dispatch',async()=>request('/v1/notifications/send',{method:'POST',body:JSON.stringify({audience:'DRIVER',type:'FIELD_TEST',title:'ASTRIDE field test',body:'Push delivery validation',deviceToken:`field-token-${runId}`,payload:{bookingId,driverId}})}));
  await step('tracking_ingest',async()=>request(`/v1/bookings/${bookingId}/tracking`,{method:'POST',body:JSON.stringify({actorType:'driver',actorId:driverId,samples:[{lat:23.2200,lng:88.3630,accuracyM:12,speedMps:3.2,heading:120,recordedAt:Date.now()},{lat:23.2210,lng:88.3625,accuracyM:10,speedMps:3.6,heading:118,recordedAt:Date.now()+5000}]})}));
  await step('tracking_readback',async()=>{const r=await request(`/v1/bookings/${bookingId}/tracking`);if((r.body.items||[]).length<1)throw new Error('No tracking samples returned');return {...r,summary:`${r.body.items.length} samples`};});
  for(const status of ['OTP_VERIFIED','IN_PROGRESS']) await step(`ride_${status.toLowerCase()}`,async()=>request(`/v1/bookings/${bookingId}/transition`,{method:'POST',body:JSON.stringify({status})}));
  if(paymentMode==='online'){
    const payment=await step('payment_order',async()=>{const r=await request('/v1/payments/orders',{method:'POST',body:JSON.stringify({bookingId,passengerId,method:'online',idempotencyKey:`field-${runId}`})});return {...r,summary:r.body.providerOrderId};});
    remember('payment_capture','MANUAL',{summary:`Complete provider checkout for payment ${payment.body.id}; verification intentionally not faked.`});
  } else remember('payment_cash','PASS',{summary:'Cash flow selected; no gateway capture required.'});
  await step('ride_completed',async()=>request(`/v1/bookings/${bookingId}/transition`,{method:'POST',body:JSON.stringify({status:'COMPLETED'})}));
  await step('event_audit',async()=>{const r=await request(`/v1/bookings/${bookingId}/events`);if((r.body.events||[]).length<6)throw new Error('Ride event trail is incomplete');return {...r,summary:`${r.body.events.length} events`};});
  report.passed=!report.steps.some(s=>s.status==='FAIL'); report.bookingId=bookingId; report.driverId=driverId; report.passengerId=passengerId; report.apiVersion=health.body.version;
} catch(error){report.error=error.message;process.exitCode=1;} finally {
  report.finishedAt=new Date().toISOString();
  await fs.mkdir(outputDir,{recursive:true});
  const stamp=new Date().toISOString().replace(/[:.]/g,'-');
  const jsonPath=path.join(outputDir,`astride-field-test-${stamp}.json`);
  await fs.writeFile(jsonPath,JSON.stringify(report,null,2));
  console.log(JSON.stringify(report,null,2));
  console.log(`Field-test report: ${jsonPath}`);
  if(serverProcess) serverProcess.kill();
}
