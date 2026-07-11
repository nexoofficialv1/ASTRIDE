# v1.4 Real Mobile Application Implementation

## Added
- Mobile-native Passenger and Driver Flutter application architecture.
- Backend API client with timeout and typed API errors.
- Encrypted token persistence via `flutter_secure_storage`.
- Persistent language selection with complete English, Bengali and Hindi key parity.
- Runtime configuration fetch for maintenance mode, minimum version, provider and payment method control.
- Passenger OTP, fare estimate, booking, live status, cancellation and history flows.
- Driver OTP, approval-aware online/offline, ride request and wallet/profile foundations.
- WebSocket reconnect service and offline GPS queue contract.
- Connectivity and location dependencies prepared for native Android/iOS integration.

## Validation scope
The environment does not contain Flutter/Dart SDK, so this release was validated through structural, dependency, locale-parity and existing backend regression tests. Native compilation and real-device execution remain release gates.
