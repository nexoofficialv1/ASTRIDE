import fs from 'node:fs';
const required = [
  'packages/brand_tokens/brand_tokens.json',
  'apps/passenger_flutter/lib/design/astride_theme.dart',
  'apps/passenger_flutter/lib/screens/astride_home_screen.dart',
  'apps/passenger_flutter/lib/screens/ride_options_screen.dart',
  'apps/driver_flutter/lib/design/astride_theme.dart',
  'apps/driver_flutter/lib/screens/astride_driver_dashboard.dart',
  'apps/driver_flutter/lib/screens/new_ride_request_screen.dart',
  'docs/ASTRIDE_BRAND_REFERENCE.png'
];
for (const path of required) if (!fs.existsSync(path)) throw new Error(`Missing ${path}`);
const tokens=JSON.parse(fs.readFileSync('packages/brand_tokens/brand_tokens.json'));
if(tokens.brandName!=='ASTRIDE') throw new Error('Brand name mismatch');
if(tokens.colors.navy!=='#0D1B3D'||tokens.colors.green!=='#22C55E'||tokens.colors.orange!=='#FF8A00') throw new Error('Brand color mismatch');
console.log('v2.0 ASTRIDE brand/UI structure passed');
