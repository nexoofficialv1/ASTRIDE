# ASTRIDE v3.11.3 — Flutter Analyze Fix

- Fixed Passenger app theme symbol mismatch (`AstrideTheme.light()` → `buildAstrideTheme()`).
- Replaced deprecated `Color.withOpacity()` calls in Driver and Partner apps with `withValues(alpha:)`.
- Intended to clear the exact GitHub Actions analyzer errors reported after v3.11.2.
