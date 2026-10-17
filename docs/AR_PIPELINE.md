# Road-anchored augmented reality: integration design

**Current camera screen is NOT world-registered AR.** The video preview only hosts non-spatial instructions. We deliberately avoid fictional blue lines appearing to hug a road.

## Required data

- Camera intrinsics: focal lengths fx/fy, optical center cx/cy, lens distortion, orientation, resolution.
- Camera extrinsics: mount position/orientation relative to vehicle and ground; calibration per setup.
- High-confidence pose: GPS + heading + inertial + VIO / ARKit / ARCore and map matching, with timestamps.
- Route geometry projected from WGS84 to local ENU coordinates; road surface and lane geometry if available.
- Camera timeline alignment and motion compensation.

## Basic projection (conceptual)

1. Convert WGS84 route vertices into local ENU coordinates centered near the camera pose.
2. Transform vertices from world coordinates to camera coordinates with `R, t` extrinsics.
3. For vertices in front of the lens: `u = fx * X/Z + cx`, `v = fy * Y/Z + cy` (after camera calibration/distortion correction).
4. Clip to visible road surface, compensate camera tilt and visual-inertial tracking latency.
5. Withhold spatial arrows when projected uncertainty exceeds thresholds or video time is stale.

A 3D map alone cannot guarantee the painted route follows the visible lane or matches the precise camera mounting angle. Distances, road heights and camera pose must be tested on representative devices.

## Native modules (later)

```text
Flutter AR camera interface
  ├── Android: ARCore / CameraX + native pose fusion
  ├── iOS: ARKit / AVFoundation + native pose fusion
  └── Platform channels -> timestamped camera pose & confidence
```

- Road-anchored AR arrows should be disabled by default until calibrated.
- A camera sourced from the car OEM can only be integrated when the OEM/OS exposes a supported feed and terms allow this use. Neither Apple CarPlay nor Android Auto by itself grants arbitrary OEM camera frames.
- AR camera should generally target a properly mounted phone or accessory, not a handheld device used while driving.
- Validation must measure calibration errors, route registration accuracy, latency, poor GPS, glare, tunnels, intersections and emergency fallback to text/voice instructions.

## Supplied code foundation

`lib/src/features/ar/geometry/route_projector.dart` implements WGS84-to-ENU approximation and a calibrated pinhole projection utility with unit tests. It deliberately remains disconnected from the live camera because a guessed camera orientation would render incorrect arrows. A future native pose provider can feed actual calibrated transforms to this utility after safety validation.
