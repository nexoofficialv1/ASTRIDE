import crypto from 'node:crypto';
const incidents=[]; const notifications=[]; const riskEvents=[]; const counters=new Map();
const clone=x=>structuredClone(x);
export function createSos(payload){const item={id:crypto.randomUUID(),status:'OPEN',priority:'CRITICAL',createdAt:new Date().toISOString(),updatedAt:new Date().toISOString(),...payload};incidents.unshift(item);return clone(item);}
export function updateSos(id,patch){const x=incidents.find(i=>i.id===id);if(!x)return null;Object.assign(x,patch,{updatedAt:new Date().toISOString()});return clone(x);}
export const listSos=()=>incidents.map(clone);
export const getSos=id=>{const x=incidents.find(i=>i.id===id);return x?clone(x):null};
export function addNotification(payload){const item={id:crypto.randomUUID(),status:'QUEUED',attempts:0,createdAt:new Date().toISOString(),...payload};notifications.unshift(item);return clone(item);}
export function updateNotification(id,patch){const x=notifications.find(i=>i.id===id);if(!x)return null;Object.assign(x,patch);return clone(x);}
export const listNotifications=()=>notifications.map(clone);
export function addRiskEvent(payload){const item={id:crypto.randomUUID(),createdAt:new Date().toISOString(),status:'OPEN',...payload};riskEvents.unshift(item);return clone(item);}
export const listRiskEvents=()=>riskEvents.map(clone);
export function hitRateLimit(key,limit,windowMs){const now=Date.now();const arr=(counters.get(key)||[]).filter(t=>now-t<windowMs);arr.push(now);counters.set(key,arr);return {allowed:arr.length<=limit,count:arr.length,limit,retryAfterMs:arr.length<=limit?0:Math.max(0,windowMs-(now-arr[0]))};}

export function exportSafetyStoreState(){return {incidents:structuredClone(incidents),notifications:structuredClone(notifications),riskEvents:structuredClone(riskEvents)};}
export function restoreSafetyStoreState(state={}){incidents.length=0;notifications.length=0;riskEvents.length=0;counters.clear();incidents.push(...(state.incidents||[]));notifications.push(...(state.notifications||[]));riskEvents.push(...(state.riskEvents||[]));}
