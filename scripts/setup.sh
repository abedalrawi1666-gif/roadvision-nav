#!/usr/bin/env bash
# Create generated Android and iOS platform files from installed Flutter SDK.
set -euo pipefail
cd "$(dirname "$0")/.."
command -v flutter >/dev/null || { echo 'Flutter is not installed or not on PATH.' >&2; exit 1; }
flutter create --platforms=android,ios --project-name roadvision_nav .
python3 scripts/configure_platforms.py
flutter pub get
flutter analyze
flutter test
printf '\nReady. Connect a physical phone and run:\n'
printf 'flutter run --dart-define=MAPBOX_PUBLIC_TOKEN=pk.YOUR_PUBLIC_TOKEN\n'
