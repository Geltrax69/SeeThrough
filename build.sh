#!/usr/bin/env bash
# ponytail: hand-rolled .app bundle. no xcodeproj to keep in sync.
set -euo pipefail
cd "$(dirname "$0")"
swift build -c release
APP=SeeThrough.app/Contents
rm -rf SeeThrough.app
mkdir -p "$APP/MacOS" "$APP/Resources"
cp .build/release/SeeThrough "$APP/MacOS/"
cp Resources/Info.plist "$APP/"
codesign --force --deep -s - SeeThrough.app
echo "built SeeThrough.app"
