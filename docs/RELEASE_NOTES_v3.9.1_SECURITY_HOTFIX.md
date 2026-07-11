# ASTRIDE v3.9.1 Security Hotfix

## Fixed
- WebSocket `/v1/live` now fails closed and requires an authentication callback.
- Ride subscriptions require a valid booking ID and either the owning passenger session token or an admin token with `rides.read`.
- OTP verification now issues a cryptographically random passenger session token instead of a predictable demo token.
- Production readiness validates the actual `ADMIN_PASSWORD`, `OPS_PASSWORD`, `FINANCE_PASSWORD`, and `ADMIN_PASSWORD_PEPPER` variables used by the admin store.
- Production admin login is blocked if any role retains a default, weak, missing, or placeholder password.
- Provider vault canonical key is `PROVIDER_CREDENTIALS_MASTER_KEY`; the old singular variable remains a temporary compatibility fallback.
- Removed the empty `services/api/src/providers/payments/index.mjs.tmp` file.

## WebSocket clients
Send `Authorization: Bearer <token>` where supported. Browser clients may use the short-lived passenger session token as `access_token` in the WebSocket query. Do not log or persist WebSocket URLs containing tokens.

## Validation
Run `node tests/security-hotfix-v391.mjs` after `npm install` in `services/api`.
