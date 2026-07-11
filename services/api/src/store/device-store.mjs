const devices=new Map();
export function registerDevice(payload){const key=`${payload.actorType}:${payload.actorId}:${payload.deviceId}`;const item={...payload,active:true,updatedAt:new Date().toISOString()};devices.set(key,item);return structuredClone(item);}
export function deactivateDevice(actorType,actorId,deviceId){const key=`${actorType}:${actorId}:${deviceId}`;const x=devices.get(key);if(!x)return null;x.active=false;x.updatedAt=new Date().toISOString();return structuredClone(x);}
export function listDevices(actorType,actorId){return [...devices.values()].filter(x=>x.actorType===actorType&&x.actorId===actorId&&x.active).map(x=>structuredClone(x));}
export function allDevices(){return [...devices.values()].map(x=>structuredClone(x));}
