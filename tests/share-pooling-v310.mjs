import assert from 'node:assert/strict';
import { canPoolBooking, buildDriverTimeline, segmentOccupancy } from '../services/api/src/domain/share-pooling-engine.mjs';
const stops=[
{id:'nibhuji',name:'নিভুজি',sequenceNo:1,lat:23.20,lng:88.30},
{id:'hospital',name:'হাসপাতাল মোড়',sequenceNo:2,lat:23.21,lng:88.31},
{id:'bus',name:'কালনা বাস স্ট্যান্ড',sequenceNo:3,lat:23.22,lng:88.32},
{id:'chawk',name:'চকবাজার',sequenceNo:4,lat:23.23,lng:88.33},
{id:'ferry',name:'কালনা খেয়াঘাট',sequenceNo:5,lat:23.24,lng:88.34},
];
const route={id:'r1',stops,defaultCapacity:4};
const session={direction:'FORWARD',capacity:4,bookings:[]};
const add=(id,pickup,drop,seats=1)=>{const x=canPoolBooking({route,session,pickupStopId:pickup,dropStopId:drop,seats,direction:'FORWARD',capacity:4});assert.equal(x.valid,true,`${id}:${x.reason}`);session.bookings.push({bookingId:id,passengerId:id,pickupStopId:pickup,dropStopId:drop,seats,segmentKeys:x.segmentKeys,status:'CONFIRMED'});};
add('P1','nibhuji','ferry');
add('P2','nibhuji','bus');
add('P3','hospital','chawk');
add('P4','bus','chawk');
add('P5','chawk','ferry');
assert.deepEqual(segmentOccupancy(session),{
'nibhuji->hospital':2,'hospital->bus':3,'bus->chawk':3,'chawk->ferry':2,
});
const timeline=buildDriverTimeline(route,session);
assert.equal(timeline.find(x=>x.stopId==='nibhuji').pickupSeats,2);
assert.equal(timeline.find(x=>x.stopId==='bus').dropSeats,1);
assert.equal(timeline.find(x=>x.stopId==='bus').pickupSeats,1);
assert.equal(timeline.find(x=>x.stopId==='chawk').dropSeats,2);
assert.equal(timeline.find(x=>x.stopId==='chawk').pickupSeats,1);
const overflow=canPoolBooking({route,session,pickupStopId:'hospital',dropStopId:'chawk',seats:2,direction:'FORWARD',capacity:4});
assert.equal(overflow.valid,false);assert.equal(overflow.reason,'SEGMENT_CAPACITY_EXCEEDED');
const reverse=canPoolBooking({route,session:{bookings:[],capacity:4,direction:'FORWARD'},pickupStopId:'chawk',dropStopId:'hospital',seats:1,direction:'FORWARD',capacity:4});
assert.equal(reverse.valid,false);assert.equal(reverse.reason,'WRONG_DIRECTION');
console.log('Share pooling v3.10 scenario passed');
