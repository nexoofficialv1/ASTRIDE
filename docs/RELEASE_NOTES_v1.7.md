# v1.7 Payment Gateway, Webhook & Reconciliation

- Razorpay/BharatPe provider adapters with encrypted server-side credentials
- HMAC webhook verification using raw request bodies
- Duplicate webhook event protection
- Payment capture from verified webhook events
- Refund provider contract
- Admin provider connection test
- Payment reconciliation records and monitoring APIs
- PostgreSQL migration 005 for webhook/reconciliation history

Live network calls remain disabled in automated tests. Production credentials and provider-specific endpoint wiring are required at deployment.
