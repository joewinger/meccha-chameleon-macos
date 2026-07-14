#!/bin/sh

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TEMPLATE="$ROOT/launcher/Meccha Chameleon.app"
WRAPPER=${SIKARUGIR_WRAPPER:-"$HOME/Applications/Sikarugir/Meccha Chameleon Test.app"}
WRAPPER_INFO="$WRAPPER/Contents/Info.plist"
ICON="$WRAPPER/Contents/Configure.app/Contents/Resources/Configure.icns"
DESTINATION=${MECCHA_APP_DESTINATION:-"$HOME/Applications/Meccha Chameleon.app"}

if [ ! -x "$WRAPPER/Contents/MacOS/Sikarugir" ] || [ ! -f "$ICON" ]; then
  printf 'Incomplete Sikarugir wrapper: %s\n' "$WRAPPER" >&2
  exit 1
fi

if [ -e "$DESTINATION" ] || [ -L "$DESTINATION" ]; then
  printf 'Refusing to overwrite existing launcher: %s\n' "$DESTINATION" >&2
  exit 1
fi

/usr/bin/plutil -replace 'Program Name and Path' \
  -string '/Program Files (x86)/Steam/steam.exe' "$WRAPPER_INFO"
/usr/bin/plutil -replace 'Program Flags' -string '' "$WRAPPER_INFO"

/bin/mkdir -p "$(dirname -- "$DESTINATION")"
/usr/bin/ditto "$TEMPLATE" "$DESTINATION"
/bin/cp "$ICON" "$DESTINATION/Contents/Resources/Meccha.icns"
printf '%s\n' "$WRAPPER" >"$DESTINATION/Contents/Resources/wrapper-path"
/bin/chmod 755 "$DESTINATION/Contents/MacOS/Meccha Chameleon"
/usr/bin/codesign --force --deep --sign - "$DESTINATION" >/dev/null

printf 'Installed: %s\n' "$DESTINATION"
printf 'You can open it from Finder or add it to the Dock.\n'
