#!/bin/sh
# Regenerate Resources/AppIcon.icns from scripts/make-icon.swift.
set -eu
cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
swift scripts/make-icon.swift "$tmp/icon.png"
set_dir="$tmp/AppIcon.iconset"
mkdir "$set_dir"
for size in 16 32 128 256 512; do
  sips -z $size $size "$tmp/icon.png" --out "$set_dir/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z $double $double "$tmp/icon.png" --out "$set_dir/icon_${size}x${size}@2x.png" >/dev/null
done
mkdir -p Resources
iconutil -c icns "$set_dir" -o Resources/AppIcon.icns
echo "wrote Resources/AppIcon.icns"
