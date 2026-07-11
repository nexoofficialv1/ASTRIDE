import assert from 'node:assert/strict';
import { WebSocket } from '../services/api/node_modules/ws/wrapper.mjs';
import { server } from '../services/api/src/server.mjs';
import { createBooking } from '../services/api/src/store/memory-store.mjs';
import { upsertPassenger, createPassengerSession } from '../services/api/src/store/passenger-store.mjs';
import { productionReadiness } from '../services/api/src/config/production-readiness.mjs';

const passenger=upsertPassenger('passenger_security_test',{mobile:'919999999999'});
const booking=createBooking({passengerId:passenger.id,pickup:{lat:23.2,lng:88.3},destination:{lat:23.21,lng:88.31}});
const session=createPassengerSession(passenger.id);
await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
const port=server.address().port;

const connect=(url,options={})=>new Promise(resolve=>{
 const ws=new WebSocket(url,options);
 ws.once('open',()=>resolve({opened:true,ws}));
 ws.once('unexpected-response',(_req,res)=>resolve({opened:false,status:res.statusCode}));
 ws.once('error',()=>{});
});

const unauth=await connect(`ws://127.0.0.1:${port}/v1/live?bookingId=${booking.id}`);
assert.equal(unauth.opened,false);assert.equal(unauth.status,401);
const wrong=await connect(`ws://127.0.0.1:${port}/v1/live?bookingId=${booking.id}`,{headers:{Authorization:'Bearer invalid'}});
assert.equal(wrong.opened,false);assert.equal(wrong.status,401);
const ok=await connect(`ws://127.0.0.1:${port}/v1/live?bookingId=${booking.id}`,{headers:{Authorization:`Bearer ${session.token}`}});
assert.equal(ok.opened,true);ok.ws.close();

const base={NODE_ENV:'production',DATABASE_URL:'postgresql://u:p@db/x',REDIS_URL:'redis://redis:6379',API_DOMAIN:'api.astride.in',ADMIN_DOMAIN:'admin.astride.in',ADMIN_PASSWORD:'VeryStrongAdmin#2026',OPS_PASSWORD:'VeryStrongOps#2026',FINANCE_PASSWORD:'VeryStrongFinance#2026',ADMIN_PASSWORD_PEPPER:'x'.repeat(64),PROVIDER_CREDENTIALS_MASTER_KEY:'y'.repeat(64)};
const weak=productionReadiness({...base,OPS_PASSWORD:'ops123'});
assert(weak.failedCritical.includes('ops_password'));
const weakFinance=productionReadiness({...base,FINANCE_PASSWORD:'finance123'});
assert(weakFinance.failedCritical.includes('finance_password'));

server.close();
console.log('security hotfix v3.9.1: PASS');
