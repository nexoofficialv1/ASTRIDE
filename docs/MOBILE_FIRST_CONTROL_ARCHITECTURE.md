# Mobile-first Control Architecture

## Product boundary
- Passenger and Driver are native mobile applications built with Flutter for Android and iOS.
- No customer-facing web application is part of this project.
- A separate public/business web product may consume the backend APIs later.
- The included Admin Control Console is an internal operations and configuration tool only.

## Remote control principle
The mobile clients call only platform APIs. External vendors are hidden behind backend adapters.

Mobile App -> Platform API -> Provider Adapter -> Map/OTP/Payment/Notification vendor

## Changes that must not require an app release
- Active/fallback provider
- Fare and commission rules
- Payment methods
- Service zones
- Feature flags
- Maintenance mode
- Supported/minimum app version
- Offers, notices and translated remote content

## Changes that may require an app release
- New native permission or operating-system capability
- New hardware integration
- A fundamentally new screen/component not already supported by the generic UI
- Security or platform compatibility updates

## Safety controls
Provider secrets remain encrypted on the server. Changes require role permission, connection tests, audit logging and rollback history.
