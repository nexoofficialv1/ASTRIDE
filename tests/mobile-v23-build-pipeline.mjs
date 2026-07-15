import fs from 'node:fs';

const must = [
  '.github/workflows/quality-gate.yml',
  '.github/workflows/android-release.yml',
  '.github/workflows/ios-release.yml',
  'mobile_build/scripts/bootstrap_mobile.sh',
  'mobile_build/scripts/build_android.sh',
  'mobile_build/scripts/build_ios.sh',
  'mobile_build/signing/android/key.properties.example',
  'mobile_build/signing/ios/ExportOptions.plist',
];

for (const path of must) {
  if (!fs.existsSync(path)) throw new Error(`Missing ${path}`);
}

for (const app of ['passenger_flutter', 'driver_flutter', 'partner_flutter']) {
  const pubspecPath = `apps/${app}/pubspec.yaml`;
  const pubspec = fs.readFileSync(pubspecPath, 'utf8');
  const versionMatch = pubspec.match(/^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$/m);

  if (!versionMatch) {
    throw new Error(`${app} missing compatible semantic version`);
  }

  const major = Number(versionMatch[1]);
  const minor = Number(versionMatch[2]);
  const build = Number(versionMatch[4]);
  const supported = major > 2 || (major === 2 && minor >= 3);

  if (!supported || build < 1) {
    throw new Error(`${app} missing compatible version`);
  }

  for (const dependency of ['flutter_launcher_icons', 'flutter_native_splash']) {
    if (!pubspec.includes(dependency)) throw new Error(`${app} missing ${dependency}`);
  }

  for (const asset of ['app_icon.png', 'splash_logo.png']) {
    if (!fs.existsSync(`apps/${app}/assets/brand/${asset}`)) {
      throw new Error(`${app} missing ${asset}`);
    }
  }
}

console.log('native build pipeline compatibility passed');
