#!/usr/bin/env bash
#
# Builds the web app with the release stamp in web/index.html synced to the
# version in pubspec.yaml.
#
# Why this exists: every file Flutter emits keeps the same name from one
# release to the next, and Flutter's service worker no longer caches anything,
# so a returning visitor's browser has nothing to tell yesterday's build from
# today's. The stamp appended to the bootstrap URL is what tells them apart —
# and a stamp that has to be edited by hand is one that eventually is not.
#
# Usage:  ./tool/build_web.sh [extra flutter build args]
#
# A plain `flutter build web --release` still works; it just ships whatever
# stamp index.html already carries.

set -euo pipefail
cd "$(dirname "$0")/.."

INDEX="web/index.html"

VERSION="$(sed -n 's/^version:[[:space:]]*\(.*[^[:space:]]\)[[:space:]]*$/\1/p' pubspec.yaml | head -1)"
if [ -z "$VERSION" ]; then
  echo "error: no 'version:' found in pubspec.yaml" >&2
  exit 1
fi

if ! grep -q '<meta name="app-version"' "$INDEX"; then
  echo "error: no <meta name=\"app-version\"> in $INDEX — nothing to stamp." >&2
  exit 1
fi

# perl rather than sed -i: portable across macOS and Linux without the
# empty-suffix argument BSD sed needs and GNU sed rejects.
perl -pi -e "s{(<meta name=\"app-version\" content=\")[^\"]*(\")}{\${1}${VERSION}\${2}}" "$INDEX"

echo "Stamped $INDEX with version $VERSION"
flutter build web --release "$@"
echo
echo "Built. Deploy with: firebase deploy --only hosting"
