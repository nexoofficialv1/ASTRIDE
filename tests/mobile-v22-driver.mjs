import fs from 'node:fs';
import path from 'node:path';
const root = process.cwd();
const driver = path.join(root,'apps','driver_flutter');
const required = [
  'lib/screens/onboarding/driver_registration_screen.dart',
  'lib/screens/onboarding/document_verification_screen.dart',
  'lib/screens/onboarding/approval_status_screen.dart',
  'lib/screens/astride_driver_dashboard.dart',
  'lib/screens/new_ride_request_screen.dart',
  'lib/screens/ride/active_ride_screen.dart',
  'lib/screens/ride/ride_history_driver_screen.dart',
  'lib/screens/earnings/driver_earnings_screen.dart',
  'lib/screens/driver_profile_screen.dart',
  'lib/state/driver_controller.dart'
];
for (const f of required) {
  if (!fs.existsSync(path.join(driver,f))) throw new Error(`Missing ${f}`);
}
const locales = ['en','bn','hi'].map(c=>JSON.parse(fs.readFileSync(path.join(driver,'assets','locales',`${c}.json`),'utf8')));
const keys = locales.map(x=>Object.keys(x).sort());
if (JSON.stringify(keys[0])!==JSON.stringify(keys[1]) || JSON.stringify(keys[0])!==JSON.stringify(keys[2])) throw new Error('Driver locale key mismatch');
if (keys[0].length < 100) throw new Error(`Expected >=100 driver locale keys, found ${keys[0].length}`);
const pubspec = fs.readFileSync(path.join(driver,'pubspec.yaml'),'utf8');
if (!/version: 2\.[2-9]\.0\+\d+/.test(pubspec)) throw new Error('Driver app version missing');
const combined = required.map(f=>fs.readFileSync(path.join(driver,f),'utf8')).join('\n');
for (const token of ['saveProfile','submitDocuments','setOnline','acceptRequest','updateRideStatus','requestSettlement']) {
  if (!combined.includes(token)) throw new Error(`Missing flow token ${token}`);
}
console.log(`v2.2 driver structure passed; locale parity ${keys[0].length}/${keys[0].length}/${keys[0].length}`);
