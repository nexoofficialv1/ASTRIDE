import assert from 'node:assert/strict';
import fs from 'node:fs';

const read = (p) => fs.readFileSync(p, 'utf8');
const workflow = read('.github/workflows/android-release.yml');
assert.match(workflow, /bootstrap_mobile\.sh "\$\{\{ inputs\.app \}\}"/);
assert.match(workflow, /validate_android_release_secrets\.sh/);
assert.match(workflow, /render_mobile_env\.sh/);
assert.match(workflow, /package_android_artifacts\.sh/);
assert.match(workflow, /ANDROID_KEYSTORE_BASE64/);
assert.match(workflow, /GOOGLE_MAPS_ANDROID_KEY/);
assert.match(workflow, /publish_github_release/);

const bootstrap = read('mobile_build/scripts/bootstrap_mobile.sh');
assert.match(bootstrap, /patch_android_signing\.py/);
const build = read('mobile_build/scripts/build_android.sh');
assert.match(build, /RELEASE_VERSION/);
assert.match(build, /RELEASE_BUILD_NUMBER/);
assert.match(build, /bootstrap_mobile\.sh/);

for (const file of [
  'mobile_build/scripts/render_mobile_env.sh',
  'mobile_build/scripts/validate_android_release_secrets.sh',
  'mobile_build/scripts/package_android_artifacts.sh',
  'mobile_build/scripts/patch_android_signing.py',
  'mobile_build/signing/android/README.md',
  'docs/SPRINT10B_RELEASE_PIPELINE.md',
]) assert.equal(fs.existsSync(file), true, `${file} missing`);

console.log('Sprint 10B signed Android release pipeline checks passed');
