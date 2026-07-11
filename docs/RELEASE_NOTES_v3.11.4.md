# ASTRIDE v3.11.4 — Flutter Test Harness Fix

- Added a valid `test/` directory and smoke test to Passenger, Driver, and Partner Flutter apps.
- Prevents `flutter test` from failing with `Test directory "test" not found`.
- Set Mobile Quality Gate matrix `fail-fast: false` so all three app results remain visible when one job fails.
- No business logic or API behavior changed.
