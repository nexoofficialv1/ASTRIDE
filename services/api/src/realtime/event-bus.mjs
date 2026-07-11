import { EventEmitter } from 'node:events';
class RideEventBus extends EventEmitter {
  publish(topic,payload){const event={topic,payload,at:new Date().toISOString()};this.emit(topic,event);this.emit('*',event);return event;}
  subscribe(topic,listener){this.on(topic,listener);return ()=>this.off(topic,listener);}
}
export const rideEventBus=new RideEventBus();
export const rideTopic=(bookingId)=>`ride:${bookingId}`;
