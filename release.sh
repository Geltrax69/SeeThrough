#!/usr/bin/env bash
# release.sh — build SeeThrough.app and wrap it in a drag-to-install .dmg.
set -euo pipefail
cd "$(dirname "$0")"
./build.sh

STAGE=$(mktemp -d)
cp -R SeeThrough.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"

rm -f SeeThrough.dmg
hdiutil create -volname SeeThrough -srcfolder "$STAGE" \
    -ov -format UDZO -quiet SeeThrough.dmg
rm -rf "$STAGE"
echo "built SeeThrough.dmg ($(du -h SeeThrough.dmg | cut -f1))"
