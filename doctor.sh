#!/bin/sh

set -u

WRAPPER=${SIKARUGIR_WRAPPER:-"$HOME/Applications/Sikarugir/Meccha Chameleon Test.app"}
CONTENTS="$WRAPPER/Contents"
INFO="$CONTENTS/Info.plist"
CUSTOM_APP="$CONTENTS/Meccha Chameleon.app"
CUSTOM_INFO="$CUSTOM_APP/Contents/Info.plist.cexe"
NATIVE_APP=${MECCHA_APP_DESTINATION:-"$HOME/Applications/Meccha Chameleon.app"}
PREFIX="$CONTENTS/SharedSupport/prefix"
STEAM="$PREFIX/drive_c/Program Files (x86)/Steam"
GAME="$STEAM/steamapps/common/MECCHA CHAMELEON"
D3DMETAL="$CONTENTS/Frameworks/renderer/d3dmetal"
FRAMEWORK="$D3DMETAL/external/D3DMetal.framework"
FAILURES=0
WARNINGS=0

pass() {
  printf 'PASS  %s\n' "$1"
}

fail() {
  printf 'FAIL  %s\n' "$1"
  FAILURES=$((FAILURES + 1))
}

warn() {
  printf 'WARN  %s\n' "$1"
  WARNINGS=$((WARNINGS + 1))
}

check_path() {
  if [ -e "$2" ]; then
    pass "$1"
  else
    fail "$1 — missing: $2"
  fi
}

plist_value() {
  /usr/bin/plutil -extract "$2" raw -o - "$1" 2>/dev/null || true
}

check_path "Rosetta 2" "/Library/Apple/usr/libexec/oah/libRosettaRuntime"
check_path "Sikarugir Creator" "/Applications/Sikarugir Creator.app"
check_path "Sikarugir wrapper" "$WRAPPER"
check_path "Sikarugir launcher" "$CONTENTS/MacOS/Sikarugir"
check_path "Bundled Wine engine" "$CONTENTS/SharedSupport/wine/version"

if [ "$(plist_value "$INFO" D3DMETAL)" = "1" ]; then
  pass "D3DMetal is enabled"
else
  fail "D3DMetal is not enabled"
fi

if [ "$(plist_value "$INFO" DXVK)" = "0" ] &&
   [ "$(plist_value "$INFO" DXMT)" = "0" ]; then
  pass "DXVK and DXMT are disabled"
else
  fail "DXVK and DXMT must remain disabled"
fi

check_path "D3DMetal Direct3D 12 DLL" "$D3DMETAL/wine/x86_64-windows/d3d12.dll"
check_path "D3DMetal DXGI DLL" "$D3DMETAL/wine/x86_64-windows/dxgi.dll"

if /usr/bin/codesign --verify --deep --strict "$FRAMEWORK" >/dev/null 2>&1 &&
   /usr/bin/codesign -dvvv "$FRAMEWORK" 2>&1 |
     /usr/bin/grep -q 'Identifier=com.apple.D3DMetal'; then
  pass "Apple D3DMetal signature"
else
  fail "Apple D3DMetal signature"
fi

check_path "Steam" "$STEAM/steam.exe"
check_path "Meccha manifest" "$STEAM/steamapps/appmanifest_4704690.acf"
check_path "Meccha executable" "$GAME/Chameleon/Binaries/Win64/PenguinHotel-Win64-Shipping.exe"
check_path "Sikarugir child launcher" "$CUSTOM_APP"

if [ "$(plist_value "$CUSTOM_INFO" 'Program Name and Path')" = "/Program Files (x86)/Steam/steam.exe" ] &&
   [ "$(plist_value "$CUSTOM_INFO" 'Program Flags')" = "-applaunch 4704690" ]; then
  pass "Child launcher uses Steam app 4704690"
else
  fail "Child launcher is not configured for Steam app 4704690"
fi

check_path "Native Meccha app" "$NATIVE_APP"

if [ -f "$NATIVE_APP/Contents/Resources/wrapper-path" ] &&
   [ "$(/bin/cat "$NATIVE_APP/Contents/Resources/wrapper-path")" = "$WRAPPER" ]; then
  pass "Native app points to this wrapper"
else
  fail "Native app does not point to this wrapper"
fi

if [ -e "$WRAPPER" ]; then
  MODE=$(/usr/bin/stat -f '%Lp' "$WRAPPER")
  case "$MODE" in
    *[2367][0-7]|*[2367]) warn "Wrapper mode $MODE is writable by other local accounts" ;;
  esac
fi

printf '\n%d failure(s), %d warning(s).\n' "$FAILURES" "$WARNINGS"
[ "$FAILURES" -eq 0 ]
