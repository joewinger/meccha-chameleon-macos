#!/bin/sh

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TEMPLATE="$ROOT/launcher/Meccha Chameleon.app"
WRAPPER=${SIKARUGIR_WRAPPER:-"$HOME/Applications/Sikarugir/Meccha Chameleon Test.app"}
CUSTOM_APP="$WRAPPER/Contents/Meccha Chameleon.app"
CUSTOM_INFO="$CUSTOM_APP/Contents/Info.plist.cexe"
DESTINATION=${MECCHA_APP_DESTINATION:-"$HOME/Applications/Meccha Chameleon.app"}

if [ ! -f "$CUSTOM_INFO" ]; then
  printf 'Missing Sikarugir child launcher: %s\n' "$CUSTOM_INFO" >&2
  printf 'Create it first with Configure -> Tools -> Custom EXE Creator.\n' >&2
  exit 1
fi

if [ -e "$DESTINATION" ] || [ -L "$DESTINATION" ]; then
  printf 'Refusing to overwrite existing launcher: %s\n' "$DESTINATION" >&2
  exit 1
fi

/usr/bin/plutil -replace 'Program Name and Path' \
  -string '/Program Files (x86)/Steam/steam.exe' "$CUSTOM_INFO"
/usr/bin/plutil -replace 'Program Flags' \
  -string '-applaunch 4704690' "$CUSTOM_INFO"

/bin/mkdir -p "$(dirname -- "$DESTINATION")"
/usr/bin/ditto "$TEMPLATE" "$DESTINATION"
/bin/cp "$CUSTOM_APP/Contents/Resources/Configure.icns" \
  "$DESTINATION/Contents/Resources/Meccha.icns"
printf '%s\n' "$WRAPPER" >"$DESTINATION/Contents/Resources/wrapper-path"
/bin/chmod 755 "$DESTINATION/Contents/MacOS/Meccha Chameleon"
/usr/bin/codesign --force --deep --sign - "$DESTINATION" >/dev/null

printf 'Installed: %s\n' "$DESTINATION"
printf 'You can open it from Finder or add it to the Dock.\n'
