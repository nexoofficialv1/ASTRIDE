#!/usr/bin/env python3
from pathlib import Path
import json,re,sys,yaml
root=Path(__file__).resolve().parents[2]
apps=('passenger_flutter','driver_flutter','partner_flutter')
required={
 'passenger_flutter':{'http','shared_preferences','flutter_secure_storage','connectivity_plus','web_socket_channel','geolocator','google_maps_flutter','flutter_map','latlong2','permission_handler','firebase_core','firebase_messaging','url_launcher','image_picker'},
 'driver_flutter':{'http','shared_preferences','flutter_secure_storage','connectivity_plus','web_socket_channel','geolocator','google_maps_flutter','flutter_map','latlong2','permission_handler','firebase_core','firebase_messaging','url_launcher','image_picker'},
 'partner_flutter':{'http','shared_preferences','flutter_secure_storage','connectivity_plus','url_launcher','image_picker'},
}
errors=[]
for app in apps:
    base=root/'apps'/app
    for rel in ['pubspec.yaml','lib/main.dart','test/smoke_test.dart','assets/brand/app_icon.png','assets/brand/splash_logo.png','assets/locales/bn.json','assets/locales/en.json']:
        if not (base/rel).exists(): errors.append(f'{app}: missing {rel}')
    try: pub=yaml.safe_load((base/'pubspec.yaml').read_text(encoding='utf-8'))
    except Exception as e:
        errors.append(f'{app}: invalid pubspec: {e}'); continue
    if 'dependency_overrides' in pub: errors.append(f'{app}: dependency_overrides must not be shipped')
    deps=set((pub.get('dependencies') or {}).keys())
    missing=required[app]-deps
    if missing: errors.append(f'{app}: missing dependencies {sorted(missing)}')
    dev=set((pub.get('dev_dependencies') or {}).keys())
    for dep in ('flutter_test','flutter_lints','flutter_launcher_icons','flutter_native_splash'):
        if dep not in dev: errors.append(f'{app}: missing dev dependency {dep}')
    imports=set()
    for f in (base/'lib').rglob('*.dart'):
        imports.update(re.findall(r"package:([A-Za-z0-9_]+)/",f.read_text(encoding='utf-8')))
    ignored={'flutter','astride_passenger','astride_driver','astride_partner'}
    undeclared={x for x in imports if x not in deps and x not in ignored}
    if undeclared: errors.append(f'{app}: undeclared package imports {sorted(undeclared)}')
    for f in (base/'assets/locales').glob('*.json'):
        try: json.loads(f.read_text(encoding='utf-8'))
        except Exception as e: errors.append(f'{app}: invalid locale {f.name}: {e}')
for env in ('production','staging'):
    f=root/'mobile_build/environments'/f'{env}.json'
    try: data=json.loads(f.read_text(encoding='utf-8'))
    except Exception as e: errors.append(f'invalid {env} environment: {e}'); continue
    if env=='production':
        if not str(data.get('API_BASE_URL','')).startswith('https://'): errors.append('production API_BASE_URL must use https')
        if not str(data.get('WS_BASE_URL','')).startswith('wss://'): errors.append('production WS_BASE_URL must use wss')
for app in ('passenger_flutter','driver_flutter'):
    firebase=root/'mobile_build/firebase'/app/'google-services.json'
    if firebase.exists():
        try:
            data=json.loads(firebase.read_text(encoding='utf-8'))
            expected={'passenger_flutter':'com.nexo.astride.passenger','driver_flutter':'com.nexo.astride.driver'}[app]
            packages={c.get('client_info',{}).get('android_client_info',{}).get('package_name') for c in data.get('client',[])}
            if expected not in packages: errors.append(f'{app}: bundled Firebase package mismatch')
        except Exception as e: errors.append(f'{app}: invalid bundled Firebase config: {e}')
# Do not treat Android google-services API keys as server secrets; scan maintained Dart/scripts instead.
for secret_pattern in (r'rzp_live_[A-Za-z0-9]+',r'sk_live_[A-Za-z0-9]+',r'-----BEGIN PRIVATE KEY-----'):
    rx=re.compile(secret_pattern)
    for base in [root/'apps/passenger_flutter',root/'apps/driver_flutter',root/'apps/partner_flutter',root/'mobile_build/scripts',root/'mobile_build/environments']:
        for f in base.rglob('*'):
            if f.resolve() == Path(__file__).resolve():
                continue
            if f.is_file() and f.stat().st_size<2_000_000:
                try: text=f.read_text(encoding='utf-8')
                except Exception: continue
                if rx.search(text): errors.append(f'embedded live secret in {f.relative_to(root)}')
if errors:
    print('Mobile source validation failed:',file=sys.stderr)
    for e in errors: print(' - '+e,file=sys.stderr)
    raise SystemExit(1)
print('Mobile source validation passed for Passenger, Driver and Partner.')
