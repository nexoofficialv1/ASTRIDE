# v0.7 Payments, Wallet, Refunds and Settlements

This milestone adds a provider-neutral payment state machine linked to a booking. Payment providers remain server-side adapters and may be changed from remote configuration without rebuilding mobile apps.

## Included
- Online and cash payment orders
- Booking-level duplicate order prevention
- Idempotency key contract
- Provider verification result handling
- Cash collection confirmation
- Partial and full refunds
- Immutable payment ledger events
- Driver commission credit on ride completion
- Driver wallet and settlement requests
- Finance/admin settlement status workflow
- Remote payment provider, currency, refund and settlement configuration

## Production boundary
The included providers are safe mock adapters. Real credentials, signed webhook verification, database transactions, gateway reconciliation and finance-role authentication are deployment-stage requirements.
