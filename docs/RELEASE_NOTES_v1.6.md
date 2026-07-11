# v1.6 OTP, Push Notification & Provider Configuration

- Provider-neutral OTP adapters for Mock, MSG91 and Twilio.
- OTP expiry, one-time use and maximum-attempt protection.
- Firebase/OneSignal/mock push adapters with server-side credentials.
- Mobile device push-token registration and deactivation APIs.
- AES-256-GCM provider credential vault; secrets are never returned to clients.
- Admin credential status, update/delete and provider test endpoints.
- New PostgreSQL migration for device registrations and OTP delivery audit.
- Runtime provider switching remains remote-config controlled.

Real provider calls require valid credentials and network access; automated tests use the mock providers.
