import fs from 'node:fs';
import path from 'node:path';
const root=process.cwd();
const app=path.join(root,'apps/passenger_flutter');
const required=[
 'lib/screens/astride_home_screen.dart',
 'lib/screens/booking_screen.dart',
 'lib/screens/ride_status_screen.dart',
 'lib/widgets/common/astride_map_canvas.dart',
];
for(const f of required){if(!fs.existsSync(path.join(app,f)))throw new Error(`Missing ${f}`)}
const booking=fs.readFileSync(path.join(app,'lib/screens/booking_screen.dart'),'utf8');
for(const token of ['FULL_TOTO','SHARE_TOTO','MOTORCYCLE','paymentPreference','safeRide','SegmentedButton']){
 if(!booking.includes(token))throw new Error(`Booking UI missing ${token}`);
}
const status=fs.readFileSync(path.join(app,'lib/screens/ride_status_screen.dart'),'utf8');
for(const token of ['SEARCHING','driverArriving','shareTrip','AstrideMapCanvas']){
 if(!status.includes(token))throw new Error(`Ride UI missing ${token}`);
}
const locales={};
for(const code of ['en','bn','hi'])locales[code]=JSON.parse(fs.readFileSync(path.join(app,`assets/locales/${code}.json`),'utf8'));
const keys=Object.keys(locales.en).sort();
for(const code of ['bn','hi']){
 const other=Object.keys(locales[code]).sort();
 if(JSON.stringify(keys)!==JSON.stringify(other))throw new Error(`Passenger locale parity failed for ${code}`);
}
for(const key of ['booking.whereTo','booking.chooseRide','payment.preference','safety.safeRide','ride.searchingNearby']){
 for(const code of ['en','bn','hi'])if(!locales[code][key])throw new Error(`Missing ${key} in ${code}`);
}
console.log(`v3.1 passenger UI contract passed: ${keys.length} keys across en/bn/hi`);
