import assert from 'node:assert/strict';
import {PresenceRegistry} from '../services/api/src/realtime/presence-registry.mjs';
import {rideEventBus,rideTopic} from '../services/api/src/realtime/event-bus.mjs';
import {readFile} from 'node:fs/promises';
const p=new PresenceRegistry({ttlSeconds:1});await p.heartbeat('d1',{lat:23.2,lng:88.3,online:true});assert.equal((await p.get('d1')).online,true);await p.remove('d1');assert.equal(await p.get('d1'),null);
let received=null;const off=rideEventBus.subscribe(rideTopic('b1'),e=>received=e);rideEventBus.publish(rideTopic('b1'),{status:'IN_PROGRESS'});off();assert.equal(received.payload.status,'IN_PROGRESS');
const sql=await readFile(new URL('../services/api/migrations/003_realtime_production_data.sql',import.meta.url),'utf8');for(const table of ['bookings','ride_events','gps_tracking_points','payment_ledger_entries','notification_deliveries','active_ride_snapshots'])assert.ok(sql.includes(table));
console.log('v1.3 realtime production data layer test passed');
