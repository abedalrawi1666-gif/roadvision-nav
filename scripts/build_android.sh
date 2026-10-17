#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${MAPBOX_PUBLIC_TOKEN:?Set MAPBOX_PUBLIC_TOKEN=pk...}"
if [[ ! -d android ]]; then echo 'Run bash scripts/setup.sh first'; exit 1; fi
flutter build apk --release --dart-define="MAPBOX_PUBLIC_TOKEN=$MAPBOX_PUBLIC_TOKEN"
printf 'APK output: build/app/outputs/flutter-apk/app-release.apk\n'
printf 'Production distribution also requires correct Android app signing.\n'
