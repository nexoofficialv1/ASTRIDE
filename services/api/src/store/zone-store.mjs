import crypto from 'node:crypto';
const zones=[];
const clone=(x)=>structuredClone(x);
export function upsertZone(input){
  if(!input.code||!input.type||!Array.isArray(input.polygon)||input.polygon.length<3) throw new Error('Invalid zone');
  const idx=zones.findIndex(z=>z.code===input.code);
  const item={id:idx>=0?zones[idx].id:crypto.randomUUID(),enabled:true,...(idx>=0?zones[idx]:{}),...clone(input),updatedAt:new Date().toISOString()};
  if(idx>=0) zones[idx]=item; else zones.push(item);
  return clone(item);
}
export function listZones(){return clone(zones);}
export function getZone(code){const z=zones.find(x=>x.code===code);return z?clone(z):null;}
export function removeZone(code){const i=zones.findIndex(z=>z.code===code);if(i<0)return false;zones.splice(i,1);return true;}
export function seedDefaultZones(){
  if(zones.length) return;
  upsertZone({code:'KALNA_SERVICE',name:'Kalna Service Area',type:'SERVICE_AREA',polygon:[{lat:23.198,lng:88.32},{lat:23.245,lng:88.32},{lat:23.245,lng:88.385},{lat:23.198,lng:88.385}]});
  upsertZone({code:'KALNA_STATION',name:'Kalna Railway Station',type:'DYNAMIC_FARE',multiplier:1.15,polygon:[{lat:23.217,lng:88.347},{lat:23.222,lng:88.347},{lat:23.222,lng:88.354},{lat:23.217,lng:88.354}]});
}
seedDefaultZones();
