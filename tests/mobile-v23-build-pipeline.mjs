import fs from 'node:fs';
const must = [
  '.github/workflows/quality-gate.yml', '.github/workflows/android-release.yml', '.github/workflows/ios-release.yml',
  'mobile_build/scripts/bootstrap_mobile.sh','mobile_build/scripts/build_android.sh','mobile_build/scripts/build_ios.sh',
  'mobile_build/signing/android/key.properties.example','mobile_build/signing/ios/ExportOptions.plist'
];
for (const p of must) if (!fs.existsSync(p)) throw new Error(`Missing ${p}`);
for (const app of ['passenger_flutter','driver_flutter','partner_flutter']) {
 const pub=fs.readFileSync(`apps/${app}/pubspec.yaml`,'utf8');
 if (!/version: (?:2\.[3-9]|3\.\d+)\.0\+\d+/.test(pub)) throw new Error(`${app} missing compatible version`);
 for (const x of ['flutter_launcher_icons','flutter_native_splash']) if(!pub.includes(x)) throw new Error(`${app} missing ${x}`);
 for (const asset of ['app_icon.png','splash_logo.png']) if(!fs.existsSync(`apps/${app}/assets/brand/${asset}`)) throw new Error(`${app} missing ${asset}`);
}
console.log('native build pipeline compatibility passed');
