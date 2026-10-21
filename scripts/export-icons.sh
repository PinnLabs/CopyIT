#!/usr/bin/env bash
# Regenerates every raster asset from the SVG masters in brand/.
#
#   brand/logo/mark-dark.svg   → app icon (32 px @2x and up)
#   brand/logo/mark-small.svg  → app icon (16 px, 16 px @2x, 32 px)
#   brand/menubar/MenuBarIcon.svg → MenuBarIcon.imageset (vector, template)
#   brand/social/social-preview.svg → brand/export/social-preview.png
#
# Requires one rasterizer: rsvg-convert (brew install librsvg) or cairosvg (pip install cairosvg).
# Usage: make icons   (or ./scripts/export-icons.sh)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BRAND="$ROOT/brand"
ASSETS="$ROOT/ClipboardManager/Resources/Assets.xcassets"
APPICON="$ASSETS/AppIcon.appiconset"
MENUBAR="$ASSETS/MenuBarIcon.imageset"
EXPORT="$BRAND/export"

render() { # <svg> <png> <width> [height]
  local svg="$1" png="$2" w="$3" h="${4:-$3}"
  if command -v rsvg-convert >/dev/null 2>&1; then
    rsvg-convert -w "$w" -h "$h" "$svg" -o "$png"
  elif command -v cairosvg >/dev/null 2>&1; then
    cairosvg "$svg" -o "$png" --output-width "$w" --output-height "$h"
  else
    echo "error: install rsvg-convert (brew install librsvg) or cairosvg (pip install cairosvg)" >&2
    exit 1
  fi
}

mkdir -p "$APPICON" "$MENUBAR" "$EXPORT/png"

# --- App icon -------------------------------------------------------------
# point size, scale, pixel size, master
ICONS=(
  "16 1 16 mark-small"
  "16 2 32 mark-small"
  "32 1 32 mark-small"
  "32 2 64 mark-dark"
  "128 1 128 mark-dark"
  "128 2 256 mark-dark"
  "256 1 256 mark-dark"
  "256 2 512 mark-dark"
  "512 1 512 mark-dark"
  "512 2 1024 mark-dark"
)

rm -f "$APPICON"/*.png
entries=()
for spec in "${ICONS[@]}"; do
  read -r pt scale px master <<<"$spec"
  suffix=""; [[ "$scale" == 2 ]] && suffix="@2x"
  file="icon_${pt}x${pt}${suffix}.png"
  render "$BRAND/logo/$master.svg" "$APPICON/$file" "$px"
  entries+=("    { \"filename\" : \"$file\", \"idiom\" : \"mac\", \"scale\" : \"${scale}x\", \"size\" : \"${pt}x${pt}\" }")
done

{
  echo '{'
  echo '  "images" : ['
  (IFS=$'\n'; echo "${entries[*]}" | sed '$!s/$/,/')
  echo '  ],'
  echo '  "info" : { "author" : "xcode", "version" : 1 }'
  echo '}'
} >"$APPICON/Contents.json"

# --- Menu bar icon (vector, rendered as template so macOS tints it) --------
cp "$BRAND/menubar/MenuBarIcon.svg" "$MENUBAR/MenuBarIcon.svg"
cat >"$MENUBAR/Contents.json" <<'JSON'
{
  "images" : [
    { "filename" : "MenuBarIcon.svg", "idiom" : "universal" }
  ],
  "info" : { "author" : "xcode", "version" : 1 },
  "properties" : {
    "preserves-vector-representation" : true,
    "template-rendering-intent" : "template"
  }
}
JSON

# --- Loose exports for README, website, press ------------------------------
for px in 16 32 64 128 256 512 1024; do
  master="mark-dark"; [[ "$px" -le 32 ]] && master="mark-small"
  render "$BRAND/logo/$master.svg" "$EXPORT/png/copyit-${px}.png" "$px"
done
render "$BRAND/social/social-preview.svg" "$EXPORT/social-preview.png" 1280 640

echo "Icons exported:"
echo "  $APPICON"
echo "  $MENUBAR"
echo "  $EXPORT"
