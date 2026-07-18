#!/usr/bin/env python3
from pathlib import Path
import json,re,sys,yaml
root=Path(__file__).resolve().parents[2]
apps=('passenger_flutter','driver_flutter','partner_flutter')
required={
 'passenger_flutter':{'http','shared_preferences','flutter_secure_storage','connectivity_plus','web_socket_channel','geolocator','google_maps_flutter','flutter_map','latlong2','permission_handler','firebase_core','firebase_messaging','firebase_app_check','cryptography','url_launcher','image_picker','mobile_scanner'},
 'driver_flutter':{'http','shared_preferences','flutter_secure_storage','connectivity_plus','web_socket_channel','geolocator','google_maps_flutter','flutter_map','latlong2','permission_handler','firebase_core','firebase_messaging','firebase_app_check','cryptography','url_launcher','image_picker','nfc_manager'},
 'partner_flutter':{'http','shared_preferences','flutter_secure_storage','connectivity_plus','url_launcher','image_picker'},
}
errors=[]
for app in apps:
    base=root/'apps'/app
    for rel in ['pubspec.yaml','lib/main.dart','test/smoke_test.dart','assets/brand/app_icon.png','assets/brand/splash_logo.png','assets/locales/bn.json','assets/locales/en.json','assets/security/astride_api_chain.pem','lib/services/pinned_transport.dart']:
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
    # Security reconstruction guards.
    session_files=list((base/'lib/models').glob('*session*.dart'))
    if not session_files or not any('refreshToken' in f.read_text(encoding='utf-8') for f in session_files):
        errors.append(f'{app}: rotating refresh token is missing from session model')
    api_client=base/'lib/services/api_client.dart'
    if not api_client.exists():
        errors.append(f'{app}: missing API client')
    else:
        api_text=api_client.read_text(encoding='utf-8')
        for marker in ('refreshToken','_refreshSession','statusCode == 401','onTokensChanged'):
            if marker not in api_text: errors.append(f'{app}: API client missing secure refresh marker {marker}')
    if app in ('passenger_flutter','driver_flutter'):
        for rel in ['lib/services/app_attestation_service.dart','lib/services/secure_chat_service.dart','lib/screens/secure_chat_screen.dart']:
            if not (base/rel).exists(): errors.append(f'{app}: missing {rel}')
        combined='\n'.join(f.read_text(encoding='utf-8') for f in (base/'lib').rglob('*.dart'))
        for forbidden in ("scheme: 'tel'","scheme: 'sms'","Uri.parse('tel:","Uri.parse('sms:"):
            if forbidden in combined: errors.append(f'{app}: direct Passenger/Driver phone exposure remains: {forbidden}')
        chat=(base/'lib/services/secure_chat_service.dart').read_text(encoding='utf-8') if (base/'lib/services/secure_chat_service.dart').exists() else ''
        for marker in ('X25519','HKDF','AES-256-GCM','FlutterSecureStorage','recipientKeyId',"'aadVersion': 2"):
            if marker not in chat: errors.append(f'{app}: secure chat missing {marker}')
        for marker in ('peerKeyChanged','safetyCode','secure-chat.peer'):
            if marker not in chat: errors.append(f'{app}: peer-key continuity missing {marker}')
        queue=base/'lib/services/location_queue.dart'
        if not queue.exists():
            errors.append(f'{app}: missing encrypted location queue')
        else:
            queue_text=queue.read_text(encoding='utf-8')
            if 'FlutterSecureStorage' not in queue_text:
                errors.append(f'{app}: offline GPS queue must use FlutterSecureStorage')
            if 'SharedPreferences' in queue_text:
                errors.append(f'{app}: offline GPS queue must not use SharedPreferences')
    if app=='passenger_flutter':
        for rel in ['lib/screens/route_scan_go_screen.dart']:
            if not (base/rel).exists(): errors.append(f'{app}: missing route Scan & Go screen')
        combined='\n'.join(f.read_text(encoding='utf-8') for f in (base/'lib').rglob('*.dart'))
        for marker in ('/v1/route-access/scan','/v1/route-access/end','capturedAt','idempotencyKey','MobileScannerController','X-Firebase-AppCheck'):
            if marker not in combined: errors.append(f'{app}: route Scan & Go missing {marker}')
    if app=='driver_flutter':
        for rel in ['lib/screens/route_service_screen.dart','lib/services/nfc_card_service.dart']:
            if not (base/rel).exists(): errors.append(f'{app}: missing {rel}')
        combined='\n'.join(f.read_text(encoding='utf-8') for f in (base/'lib').rglob('*.dart'))
        for marker in ('/v1/driver/route-service/start-trip','/v1/driver/route-service/heartbeat','/v1/driver/route-service/card-tap','NfcManager.instance','cardTapGoReady','secure DESFire reader'):
            if marker not in combined: errors.append(f'{app}: route Tap & Go missing {marker}')

    # Route screens must not expose raw exception strings to passengers or drivers.
    for route_rel in ('lib/screens/route_scan_go_screen.dart','lib/screens/route_service_screen.dart'):
        route_file=base/route_rel
        if route_file.exists() and "Text('$error')" in route_file.read_text(encoding='utf-8'):
            errors.append(f'{app}: raw route exception is displayed in {route_rel}')
    pub_version=str(pub.get('version') or '')
    if pub_version != '3.23.0+348': errors.append(f'{app}: expected ledger release build version 3.23.0+348, found {pub_version}')

    # Flutter 3.41+ deprecation guards. Keep analyzer strict instead of suppressing infos.
    for f in (base/'lib').rglob('*.dart'):
        text=f.read_text(encoding='utf-8')
        if '.withOpacity(' in text:
            errors.append(f'{app}: deprecated Color.withOpacity in {f.relative_to(root)}; use withValues(alpha: ...)')
        lines=text.splitlines()
        for idx,line in enumerate(lines):
            if 'DropdownButtonFormField' not in line:
                continue
            head=[]
            for following in lines[idx+1:idx+20]:
                if re.match(r'\s*items\s*:', following):
                    break
                head.append(following)
            if any(re.match(r'\s*value\s*:', following) for following in head):
                errors.append(f'{app}: deprecated DropdownButtonFormField.value in {f.relative_to(root)}; use initialValue')
                break
cert_script=root/'mobile_build/scripts/fetch_api_certificate.sh'
if not cert_script.exists(): errors.append('missing TLS certificate pinning build script')
else:
    cert_text=cert_script.read_text(encoding='utf-8')
    for marker in ('openssl s_client','verify_return_error','astride_api_chain.pem'):
        if marker not in cert_text: errors.append(f'TLS pinning script missing {marker}')
native_patch=(root/'mobile_build/scripts/patch_native.py').read_text(encoding='utf-8')
for marker in ('FLAG_SECURE','WindowManager.LayoutParams.FLAG_SECURE'):
    if marker not in native_patch: errors.append(f'native security patch missing {marker}')

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
