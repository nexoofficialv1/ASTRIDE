# v0.6 Live Map, GPS and Background Tracking

Implemented foundation:
- Provider-neutral route API with primary/fallback map adapters.
- Batched driver/passenger GPS ingestion.
- Accuracy, range, order and batch-size validation.
- Latest driver location with stale-location detection.
- Ride tracking snapshots and bounded point history.
- Offline mobile queue/flush contract for weak-network recovery.
- Remote tracking intervals and thresholds through runtime configuration.

Production provider SDK credentials and native Android/iOS background services remain deployment-time integrations. No provider secret belongs in either mobile application.
