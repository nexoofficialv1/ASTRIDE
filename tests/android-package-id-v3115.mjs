import fs from 'node:fs';
import assert from 'node:assert/strict';

const bootstrap = fs.readFileSync('mobile_build/scripts/bootstrap_mobile.sh', 'utf8');
assert(!bootstrap.includes('ORG="in.astride"'), 'Reserved Java identifier "in" must not be used as Android namespace prefix');
assert(bootstrap.match(/ORG="com\.astride"/g)?.length === 3, 'All three apps must use com.astride as the Flutter org');

const patcher = fs.readFileSync('mobile_build/scripts/patch_native.py', 'utf8');
assert(patcher.includes('com/astride/astride_driver'), 'Driver native Kotlin sources must be copied into the generated package path');
assert(patcher.includes('package com.astride.astride_driver'), 'Driver native Kotlin package declaration must match Android namespace');

console.log('Android package namespace checks passed');
