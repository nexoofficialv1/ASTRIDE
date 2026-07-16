# ASTRIDE Three Apps Build 346 — Analyzer & Build Resilience Fix

Version: `3.20.0+346`

## সংশোধন

- Passenger, Driver ও Partner-এর `pinned_transport.dart` থেকে redundant `dart:typed_data` import সরানো হয়েছে।
- APK compilation workflows-এ `flutter analyze --no-fatal-infos` ব্যবহার করা হয়েছে, যাতে শুধুমাত্র info-level lint APK build বন্ধ না করে।
- Error ও warning-level analyzer findings এখনও build ব্যর্থ করবে।
- আলাদা `Mobile Quality Gate` workflow strict `flutter analyze` বজায় রাখে।
- Phase 2 security reconstruction, certificate pinning, secure chat, App Check এবং Firebase injection অপরিবর্তিত আছে।

## Build input

- Environment: `production`
- Mode: `debug`
- Version: `3.20.0`
- Build number: `346`
