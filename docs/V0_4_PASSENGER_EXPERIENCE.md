# v0.4 Passenger Booking Experience

## Mobile flow
Language selection → OTP login → booking map shell → pickup/destination → fare estimate → payment method → driver search → assigned driver → ride lifecycle → history/rating/complaint.

## Backend additions
OTP provider abstraction, passenger profiles, saved places, fare engine, passenger booking history, cancellation endpoint, rating and complaint intake, locale content version and remote fare configuration.

## Update policy
Fare, payment availability, minimum app version, maintenance, language content version and provider selection are remote configuration. Native app updates remain reserved for native capability or security changes.

## Production gaps intentionally remaining
Real GPS/map SDK, production SMS credentials, payment SDK checkout, push notifications, persistent PostgreSQL repositories, authentication middleware and live WebSocket tracking are scheduled for later builds.
