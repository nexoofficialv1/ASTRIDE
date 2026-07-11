import fs from 'node:fs';import assert from 'node:assert/strict';
const read=p=>fs.readFileSync(new URL('../'+p,import.meta.url),'utf8');
for(const app of ['passenger_flutter','driver_flutter']){
 const pub=read(`apps/${app}/pubspec.yaml`);assert.match(pub,/version: (?:1\.5\.0\+15|[23]\.[0-9]+\.0\+[0-9]+)/);assert.match(pub,/google_maps_flutter/);assert.match(pub,/permission_handler/);
 assert.match(read(`apps/${app}/lib/services/native_location_service.dart`),/Geolocator\.getPositionStream/);
 assert.match(read(`apps/${app}/lib/services/background_ride_tracker.dart`),/LocationQueue/);
 assert.match(read(`apps/${app}/lib/widgets/provider_map.dart`),/GoogleMap/);
}
const dm=read('apps/driver_flutter/android/app/src/main/AndroidManifest.xml');assert.match(dm,/ACCESS_BACKGROUND_LOCATION/);assert.match(dm,/FOREGROUND_SERVICE_LOCATION/);
const pi=read('apps/passenger_flutter/ios/Runner/Info.plist');assert.match(pi,/NSLocationWhenInUseUsageDescription/);
const di=read('apps/driver_flutter/ios/Runner/Info.plist');assert.match(di,/NSLocationAlwaysAndWhenInUseUsageDescription/);assert.match(di,/UIBackgroundModes/);
console.log('v1.5 native mobile structure test passed');
