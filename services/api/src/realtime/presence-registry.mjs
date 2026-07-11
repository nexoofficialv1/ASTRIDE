const memory=new Map();
const now=()=>Date.now();
export class PresenceRegistry{
 constructor({redis=null,ttlSeconds=45}={}){this.redis=redis;this.ttlSeconds=ttlSeconds;}
 key(id){return `driver:presence:${id}`;}
 async heartbeat(driverId,data){const item={driverId,...data,updatedAt:new Date().toISOString(),expiresAt:now()+this.ttlSeconds*1000};if(this.redis){await this.redis.set(this.key(driverId),JSON.stringify(item),{EX:this.ttlSeconds});}else memory.set(driverId,item);return item;}
 async get(driverId){if(this.redis){const raw=await this.redis.get(this.key(driverId));return raw?JSON.parse(raw):null;}const item=memory.get(driverId);if(!item||item.expiresAt<=now()){memory.delete(driverId);return null;}return item;}
 async remove(driverId){if(this.redis)await this.redis.del(this.key(driverId));else memory.delete(driverId);}
 async list(ids=[]){const out=[];for(const id of ids){const p=await this.get(id);if(p)out.push(p);}return out;}
}
export const memoryPresenceSize=()=>[...memory.values()].filter(x=>x.expiresAt>now()).length;
