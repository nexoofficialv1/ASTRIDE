import { WebSocketServer } from 'ws';
import { rideEventBus,rideTopic } from './event-bus.mjs';
const safeSend=(ws,data)=>{if(ws.readyState===ws.OPEN)ws.send(JSON.stringify(data));};
const reject=(socket,status,message)=>{socket.write(`HTTP/1.1 ${status} ${message}\r\nConnection: close\r\n\r\n`);socket.destroy();};
export function attachRideWebSocket(server,{authenticate}={}){
 if(typeof authenticate!=='function')throw new Error('WebSocket authenticate callback is required');
 const wss=new WebSocketServer({noServer:true});
 server.on('upgrade',(req,socket,head)=>{
  const url=new URL(req.url,'http://localhost');
  if(url.pathname!='/v1/live'){socket.destroy();return;}
  const bookingId=url.searchParams.get('bookingId');
  if(!bookingId){reject(socket,400,'Bad Request');return;}
  let auth;try{auth=authenticate(req,url,bookingId);}catch{reject(socket,401,'Unauthorized');return;}
  if(!auth){reject(socket,401,'Unauthorized');return;}
  wss.handleUpgrade(req,socket,head,ws=>{ws.auth=auth;wss.emit('connection',ws,req,url);});
 });
 wss.on('connection',(ws,req,url)=>{const bookingId=url.searchParams.get('bookingId');const unsubscribe=rideEventBus.subscribe(rideTopic(bookingId),e=>safeSend(ws,e));safeSend(ws,{topic:'system',payload:{connected:true,bookingId},at:new Date().toISOString()});ws.on('message',raw=>{try{const m=JSON.parse(raw);if(m.type==='PING')safeSend(ws,{type:'PONG',at:new Date().toISOString()});}catch{safeSend(ws,{type:'ERROR',error:'invalid_json'});}});ws.on('close',()=>unsubscribe?.());});
 return wss;
}
