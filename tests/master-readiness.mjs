import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';

const root = path.resolve(import.meta.dirname, '..');
const apps = ['passenger_flutter', 'driver_flutter'];

for (const app of apps) {
  const dir = path.join(root, 'apps', app);
  for (const file of ['pubspec.yaml', 'lib/main.dart', 'native_overrides/AndroidManifest.xml', 'native_overrides/Info.plist']) {
    assert.ok(fs.existsSync(path.join(dir, file)), `${app}: missing ${file}`);
  }

  const dartFiles = [];
  const walk = (d) => {
    for (const entry of fs.readdirSync(d, { withFileTypes: true })) {
      const full = path.join(d, entry.name);
      if (entry.isDirectory()) walk(full);
      else if (entry.name.endsWith('.dart')) dartFiles.push(full);
    }
  };
  walk(path.join(dir, 'lib'));
  assert.ok(dartFiles.length >= 15, `${app}: unexpectedly small Dart source tree`);

  for (const file of dartFiles) {
    const source = fs.readFileSync(file, 'utf8');
    for (const match of source.matchAll(/import\s+['"]([^'"]+)['"]/g)) {
      const spec = match[1];
      if (spec.startsWith('package:') || spec.startsWith('dart:')) continue;
      const target = path.resolve(path.dirname(file), spec);
      assert.ok(fs.existsSync(target), `${path.relative(root, file)} imports missing ${spec}`);
    }
  }

  const locales = ['en', 'bn', 'hi'].map((code) => JSON.parse(fs.readFileSync(path.join(dir, 'assets/locales', `${code}.json`), 'utf8')));
  const keys = locales.map((value) => Object.keys(value).sort());
  assert.deepEqual(keys[1], keys[0], `${app}: Bengali locale key mismatch`);
  assert.deepEqual(keys[2], keys[0], `${app}: Hindi locale key mismatch`);
}

for (const file of [
  'services/api/src/server.mjs',
  'services/api/package-lock.json',
  'apps/admin_control_console/index.html',
  'docker-compose.production.yml',
  'mobile_build/scripts/bootstrap_mobile.sh',
  '.github/workflows/android-test-apk.yml'
]) {
  assert.ok(fs.existsSync(path.join(root, file)), `missing master component: ${file}`);
}

console.log('ASTRIDE master readiness contract passed');
