# v0.3 Core Operations

1. Passenger creates a booking.
2. Backend moves it from DRAFT to SEARCHING.
3. Only approved, online drivers with a current location are considered.
4. Drivers are ranked by distance, then rating.
5. The selected driver is assigned through a controlled state transition.
6. Invalid ride status jumps are rejected.
7. Every important ride change is stored as a ride event.
8. Runtime configuration controls matching radius, provider selection, payment methods and maintenance mode.
9. External providers are invoked through adapters and can use a fallback provider.
