# ASTRIDE VPS-first bootstrap architecture (v3.9.3)

1. Build signed Passenger, Driver and Partner APKs with only the final API/WS domain and signing key. Google Maps and Firebase build files are optional. The apps start with OSM/server fallback and push disabled.
2. Deploy API and Admin Console to VPS with PostgreSQL, Redis, strong admin passwords and `PROVIDER_CREDENTIALS_MASTER_KEY`.
3. Mount `/var/lib/astride` as persistent storage. Runtime settings and encrypted provider credentials survive restarts.
4. First production start is allowed in bootstrap mode. Public booking/driver-online operations default OFF.
5. Login to Admin Console → Providers. Paste credential JSON, save, test, choose active provider/mode.
6. Configure Firebase with service-account fields plus public `clients.passenger` and `clients.driver` FirebaseOptions. Apps fetch only sanitized public FirebaseOptions at runtime; private keys never leave the server.
7. Enable service/new bookings/driver online only after provider tests pass.

## Android map limitation
OSM and all server-side geocoding/routing can be switched without rebuilding. The native Google Maps Android SDK key is a manifest/build resource. To display native Google Maps after an APK was built without that restricted key, a new signed APK is technically required. This does not affect backend Mappls/Google routing or OSM map display.
