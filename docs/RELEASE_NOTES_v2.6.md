# ASTRIDE v2.6 — Android Compile Gate Fixes

This release repairs concrete CI/native-bootstrap defects found in v2.5:

1. `quality-gate.yml` called the bootstrap script without its required app argument.
2. Native bootstrap replaced the complete generated Android manifest and iOS plist, which removed Flutter entry-point/bundle metadata.
3. Debug APK builds were blocked when Firebase secrets were absent, even though compile-only verification should not require live Firebase.
4. Google Maps key injection had no safe empty compile-time fallback.

The new native patcher preserves Flutter-generated files and adds only ASTRIDE permissions, labels, location descriptions, background modes, and map metadata. A matrix GitHub workflow now compiles both Android apps and uploads both debug APKs.
