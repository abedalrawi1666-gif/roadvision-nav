#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${MAPBOX_PUBLIC_TOKEN:?Set MAPBOX_PUBLIC_TOKEN=pk...}"
[[ "$(uname)" == 'Darwin' ]] || { echo 'iOS release builds require macOS + Xcode'; exit 1; }
[[ -d ios ]] || { echo 'Run bash scripts/setup.sh first'; exit 1; }
flutter build ipa --release --dart-define="MAPBOX_PUBLIC_TOKEN=$MAPBOX_PUBLIC_TOKEN"
printf 'Check build/ios/ipa/ for signed IPA (Apple signing required).\n'
