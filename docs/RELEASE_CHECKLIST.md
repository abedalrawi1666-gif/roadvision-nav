# Release checklist — do not publish until checked

## Build and ownership
- [ ] Flutter and package versions locked in `pubspec.lock`, and `flutter analyze`, `flutter test` pass.
- [ ] Android build succeeds on devices and relevant API levels.
- [ ] iOS build succeeds on physical iPhone and desired iOS versions.
- [ ] Mapbox public token available, properly restricted; downloads token stored only in private build environment.
- [ ] App name, package name/Bundle ID, signing identity and store developer accounts owned by publisher.
- [ ] Google Play signed AAB, Apple signed IPA/Archive and provisioning configuration.
- [ ] Store icon/screenshots/descriptions localized; accessibility and RTL reviewed.

## Navigation and camera
- [ ] Map matching and route progress integration, verified ETA and rerouting implemented.
- [ ] Lost GPS / poor accuracy / no network / permissions revoked safely handled.
- [ ] No inaccurate AR arrows presented to a driver.
- [ ] If world-anchored AR enabled: calibration, confidence gating, latency, occlusion and device compatibility tested.
- [ ] Camera feed source contract confirmed for external car hardware and legal licensing.
- [ ] Field-testing policy: passenger/operator, not driver interacting with handset.
- [ ] Road laws, distraction risk, app-store rules, applicable vehicle safety requirements reviewed.

## Privacy and ops
- [ ] Privacy policy and official support contacts defined.
- [ ] Third-party mapping data licensing and attributions confirmed.
- [ ] Terms of use, crash reporting consent, retention and incident handling established.
- [ ] API budgets, quotas, error handling and rate limiting configured.
- [ ] Operational monitoring and incident response for navigation inaccuracies planned.
