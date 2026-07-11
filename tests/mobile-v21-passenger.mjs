import fs from 'node:fs';
import assert from 'node:assert/strict';
const root=new URL('../',import.meta.url);
const read=p=>fs.readFileSync(new URL(p,root),'utf8');
for(const p of [
'apps/passenger_flutter/lib/screens/onboarding/splash_screen.dart',
'apps/passenger_flutter/lib/screens/onboarding/onboarding_screen.dart',
'apps/passenger_flutter/lib/screens/ride/driver_searching_screen.dart',
'apps/passenger_flutter/lib/screens/ride/ride_completed_screen.dart',
'apps/passenger_flutter/lib/screens/login_screen.dart']) assert.ok(read(p).length>300,p);
const locales=['en','bn','hi'].map(c=>JSON.parse(read(`packages/locales/${c}.json`)));
const keys=Object.keys(locales[0]).sort();
assert.ok(keys.length>=75,`expected >=75 keys, found ${keys.length}`);
for(const l of locales) assert.deepEqual(Object.keys(l).sort(),keys);
const pub=read('apps/passenger_flutter/pubspec.yaml');
assert.match(pub,/version: 2\.[1-9]\.0\+\d+/);
assert.match(pub,/assets\/locales\//);
console.log(`v2.1 passenger UI contract passed (${keys.length} locale keys × 3 languages)`);
