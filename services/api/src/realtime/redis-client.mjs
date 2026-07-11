import { createClient } from 'redis';
let client=null;
export async function getRedis(){if(!process.env.REDIS_URL)return null;if(client?.isReady)return client;client=createClient({url:process.env.REDIS_URL});client.on('error',e=>console.error('Redis error',e.message));await client.connect();return client;}
export async function redisHealth(){try{const c=await getRedis();if(!c)return {mode:'memory',ok:true};return {mode:'redis',ok:(await c.ping())==='PONG'};}catch(e){return {mode:'redis',ok:false,error:e.message};}}
