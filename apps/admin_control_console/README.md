# Admin Control Console v1.8

Secure internal web console for operating the mobile ride platform. It is not a passenger-facing booking website.

## Functions

- Live dashboard and operational status
- Ride, driver, payment and settlement monitoring
- SOS, risk-event and complaint handling
- Notification delivery monitoring
- Map, OTP, payment and push-provider selection
- Provider connection testing and credential-status visibility
- Service/feature controls
- Audit and persistence status
- English, Bengali and Hindi interface modes

Serve this folder behind HTTPS and an authenticated reverse proxy. Configure the API base URL on the login screen. Do not expose the console publicly without IP restrictions, MFA and production admin credentials.
