# Architecture

```text
UI: NavigationShell
  ├── Map3dScreen (Mapbox Maps SDK)
  ├── ArCameraScreen (Flutter camera, NON-world-anchored)
  ├── DestinationSearchSheet
  └── route + next maneuver summary

NavigationController (ChangeNotifier)
  ├── LocationService -> geolocator -> GPS foreground stream
  ├── MapboxApi -> Search/Geocoding v6 and Directions v5
  └── VoiceService -> flutter_tts

Domain
  ├── GeoCoordinate (lat / lon)
  ├── VehiclePose (+ GPS heading, accuracy, timestamp)
  ├── Destination
  ├── NavigationStep
  └── NavigationRoute
```

## User flow

1. App displays Mapbox map; camera remains inactive.
2. User explicitly requests foreground location permission.
3. User searches for a destination (Mapbox Geocoding).
4. Controller fetches Directions route from user's current position to selected result.
5. Mapbox renders road geometry as Polyline annotation; route summary is shared with camera view.
6. Camera view starts rear camera, keeps route as text-based HUD only.

## Production replacement work

1. Background/resume-safe location controller & persistence.
2. Road snapping/map matching, safe route progress, remaining ETA and robust rerouting.
3. AR projection of road geometry onto calibrated camera intrinsics & extrinsics.
4. Visual-inertial tracking, depth/occlusion, lane inference with confidence gating.
5. Separate camera input provider abstraction (built-in phone camera vs external supported devices).
6. Offline or degraded-network behavior, telemetry with consent, localization, accessibility.
7. Field/simulation testing with passenger, not driver; safety assessment and regulatory review.
8. API usage permissions, map attributions, trademark and licensing verification.

## API dependencies

- Mapbox Maps SDK is the renderer, not a route provider.
- Mapbox Geocoding v6 requires API authorization and may have usage restrictions.
- Mapbox Directions v5 provides routes; distance/time are service estimates.
- Routes are never invented locally if the API returns no route.
- No server credentials or user-specific billing account is embedded in the code.

## Environment-dependent checks

Dart package/API compatibility must be verified with Flutter installed and package release notes. Mapbox token/maven auth may be required during build; iOS requires Mac. No Flutter executable was available while preparing this source package.
