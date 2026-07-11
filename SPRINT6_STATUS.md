# ASTRIDE Master v3.3 — Sprint 6 Status

## Implemented source

- One role-based Partner Flutter app for Promoter and Area Promoter.
- Premium dashboard with total/online driver, completed rides, acceptance and monthly target.
- Custom date-range selector connected to partner dashboard and driver analytics APIs.
- Driver search and filters: all, online, needs attention and top performers.
- Driver detail screen with requests, completed/rejected/cancelled rides, acceptance, cancellation, rating, online hours and late arrivals.
- Auditable Encourage, Performance Warning and Training Reminder actions.
- Earnings dashboard with pending/withdrawable balances, next settlement date and monthly withdrawal lock.
- Profile, role scope notice, logout and English/Bengali/Hindi switching.
- Existing backend role scope and monthly settlement APIs preserved.

## Automated validation

Run:

```bash
npm run test:sprint6
```

The native APK must still be compiled by the GitHub Android Compile Check because Flutter/Android SDK is not available in this build environment.
