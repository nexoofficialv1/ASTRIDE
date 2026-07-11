import assert from 'node:assert/strict';
import fs from 'node:fs';
import { productionReadiness } from '../services/api/src/config/production-readiness.mjs';

const unsafe = productionReadiness({ NODE_ENV: 'production', DATABASE_URL: 'CHANGE_ME' });
assert.equal(unsafe.ready, false);
assert(unsafe.failedCritical.includes('database_url'));

const dart = fs.readFileSync(new URL('../apps/driver_flutter/lib/services/native_location_service.dart', import.meta.url), 'utf8');
const tracker = fs.readFileSync(new URL('../apps/driver_flutter/lib/services/background_ride_tracker.dart', import.meta.url), 'utf8');
const native = fs.readFileSync(new URL('../apps/driver_flutter/android_native/app/src/main/kotlin/in/astride/driver/LocationForegroundService.kt', import.meta.url), 'utf8');
const patcher = fs.readFileSync(new URL('../mobile_build/scripts/patch_native.py', import.meta.url), 'utf8');
assert(dart.includes('MethodChannel'));
assert(tracker.includes('startForegroundTracking'));
assert(native.includes('START_STICKY'));
assert(native.includes('FOREGROUND_SERVICE_TYPE_LOCATION'));
assert(patcher.includes('foregroundServiceType'));
console.log('Sprint 10 production readiness checks passed');
