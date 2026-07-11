import fs from 'node:fs';
import path from 'node:path';
const root = path.resolve(import.meta.dirname, '..');
const required = [
  '.gitignore',
  '.github/workflows/android-test-apk.yml',
  'mobile_build/environments/staging.json',
  'mobile_build/environments/production.json',
  'mobile_build/scripts/inject_firebase.sh',
  'mobile_build/scripts/build_test_apk.sh',
];
for (const rel of required) {
  if (!fs.existsSync(path.join(root, rel))) throw new Error(`Missing ${rel}`);
}
for (const app of ['passenger_flutter','driver_flutter']) {
  const pubspec = fs.readFileSync(path.join(root,'apps',app,'pubspec.yaml'),'utf8');
  if (!pubspec.includes('version: 2.4.0+24')) throw new Error(`${app} version not bumped`);
  const config = fs.readFileSync(path.join(root,'apps',app,'lib/core/app_config.dart'),'utf8');
  for (const token of ['APP_ENV','API_BASE_URL','WS_BASE_URL','Production requires HTTPS/WSS']) {
    if (!config.includes(token)) throw new Error(`${app} missing ${token}`);
  }
}
const staging=JSON.parse(fs.readFileSync(path.join(root,'mobile_build/environments/staging.json'),'utf8'));
const production=JSON.parse(fs.readFileSync(path.join(root,'mobile_build/environments/production.json'),'utf8'));
if (!staging.API_BASE_URL.startsWith('https://')) throw new Error('staging API must use HTTPS');
if (!production.API_BASE_URL.startsWith('https://') || !production.WS_BASE_URL.startsWith('wss://')) throw new Error('production endpoints must be secure');
const gitignore=fs.readFileSync(path.join(root,'.gitignore'),'utf8');
for (const secret of ['google-services.json','GoogleService-Info.plist','*.jks','*.p12']) {
  if (!gitignore.includes(secret)) throw new Error(`gitignore missing ${secret}`);
}
console.log('v2.4 GitHub-ready repository contract passed');
