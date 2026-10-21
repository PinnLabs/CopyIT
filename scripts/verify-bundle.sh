#!/usr/bin/env bash
# Fails if the built app is missing its compiled icons.
# Usage: scripts/verify-bundle.sh path/to/ClipboardManager.app
set -euo pipefail

app="${1:?usage: $0 path/to/App.app}"
car="$app/Contents/Resources/Assets.car"

[[ -f "$car" ]] || { echo "error: $car not found" >&2; exit 1; }

info="$(xcrun assetutil --info "$car")"
for name in AppIcon MenuBarIcon; do
  grep -q "\"$name\"" <<<"$info" || { echo "error: $name missing from $car" >&2; exit 1; }
done
echo "OK: $app has AppIcon and MenuBarIcon"
