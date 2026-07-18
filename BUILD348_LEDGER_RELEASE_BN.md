# ASTRIDE Mobile Build 348 — v3.23.0

- Passenger App: ASTRIDE Ride Credit balance, held fare, verified UPI recharge এবং non-transferable credit notice।
- Normal Booking: Ride Credit payment request এখন backend hold lifecycle ব্যবহার করে।
- Route Scan & Go: maximum fare hold, actual capture, release ও safe duplicate retry।
- Driver App: hard-coded earning demo সরানো হয়েছে; real earning transactions ও settlement statuses দেখায়।
- Partner App: real commission/withdrawal status বজায় আছে।
- তিনটি app: safe GET/idempotent-request retry, token refresh এবং friendly error handling।
- Version: `3.23.0+348`।

APK/AAB build workflow: `.github/workflows/android-three-apps-build.yml`। Release signing secrets এবং production environment validation pass না করলে workflow release artifacts তৈরি করবে না।
