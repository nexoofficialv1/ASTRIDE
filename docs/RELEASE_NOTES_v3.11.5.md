# ASTRIDE v3.11.5 — Android Namespace Fix

- Replaced invalid Flutter organization prefix `in.astride` with `com.astride` for Passenger, Driver and Partner apps.
- Android application IDs now generate as:
  - `com.astride.astride_passenger`
  - `com.astride.astride_driver`
  - `com.astride.astride_partner`
- Updated Driver native foreground-location Kotlin package injection to match the generated Android namespace.
- Added a regression test that prevents reserved Java identifiers from being used in future Android package IDs.
