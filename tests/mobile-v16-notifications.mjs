import assert from 'node:assert/strict'; import fs from 'node:fs'; import path from 'node:path';
const root=path.resolve(import.meta.dirname,'..');
for(const app of ['passenger_flutter','driver_flutter']){
 const base=path.join(root,'apps',app); const pub=fs.readFileSync(path.join(base,'pubspec.yaml'),'utf8');
 assert.match(pub,/firebase_messaging:/); assert.ok(fs.existsSync(path.join(base,'lib/services/push_notification_service.dart')));
 const manifest=fs.readFileSync(path.join(base,'android/app/src/main/AndroidManifest.xml'),'utf8'); assert.match(manifest,/POST_NOTIFICATIONS/);
}
console.log('v1.6 mobile push notification structure passed');
