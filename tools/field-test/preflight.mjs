#!/usr/bin/env node
const base=(process.env.ASTRIDE_BASE_URL||'').replace(/\/$/,'');
if(!base) throw new Error('ASTRIDE_BASE_URL is required');
const checks=[];
for(const route of ['/health','/ready','/v1/mobile/config?app=passenger','/v1/mobile/config?app=driver']){
  const started=Date.now();
  try{const r=await fetch(base+route);const body=await r.json();checks.push({route,status:r.status,ok:r.ok,durationMs:Date.now()-started,version:body.version||body.localeContentVersion||null});}
  catch(error){checks.push({route,status:0,ok:false,error:error.message});}
}
console.log(JSON.stringify({base,checkedAt:new Date().toISOString(),checks,passed:checks.every(x=>x.ok)},null,2));
if(!checks.every(x=>x.ok))process.exitCode=1;
