#!/bin/sh
# Build SameLayout.app into ./build. Pass --install to copy it to ~/Applications.
set -eu
cd "$(dirname "$0")"

swift build -c release
app=build/SameLayout.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp .build/release/SameLayout "$app/Contents/MacOS/"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key><string>com.amaotone.SameLayout</string>
  <key>CFBundleName</key><string>SameLayout</string>
  <key>CFBundleExecutable</key><string>SameLayout</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST
codesign --force --sign - "$app"
echo "built $app"

if [ "${1:-}" = "--install" ]; then
  mkdir -p ~/Applications
  rm -rf ~/Applications/SameLayout.app
  cp -R "$app" ~/Applications/
  echo "installed ~/Applications/SameLayout.app"
fi
