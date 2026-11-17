#!/usr/bin/env bash
# Remove packages for user 0 only (the APK stays in /system, so it is fully reversible),
# after saving each APK and recording it in the backup folder.
#
# Usage: tools/remove.sh <backup-dir> <package> [package ...]
#        MODE=disable tools/remove.sh <backup-dir> <package> ...   # pm disable-user instead
#
# Refuses Android core packages that can stop the device booting or leave it without input.
set -uo pipefail
[[ $# -ge 2 ]] || { echo "usage: $0 <backup-dir> <pkg> [pkg ...]"; exit 2; }
dir=$1; shift
[[ -f "$dir/removed_packages.txt" ]] || { echo "No $dir/removed_packages.txt: run tools/backup.sh first."; exit 2; }
mode=${MODE:-uninstall}

# Never touch these (exact names or prefixes ending in '*').
PROTECTED=(
  android com.android.systemui com.android.settings com.android.shell com.android.phone
  com.android.permissioncontroller com.google.android.permissioncontroller
  com.android.packageinstaller com.google.android.packageinstaller
  com.android.extservices com.google.android.ext.services android.ext.services
  com.android.ext.shared com.google.android.ext.shared android.ext.shared
  com.android.modulemetadata com.google.android.modulemetadata
  'com.google.android.overlay.modules*' com.android.networkstack 'com.android.networkstack*'
  'com.google.android.networkstack*' com.android.inputmethod.latin com.google.android.inputmethod.latin
  com.android.bluetooth com.android.nfc com.android.documentsui com.google.android.documentsui
  com.android.launcher3 com.android.vending com.google.android.gms com.google.android.gsf
  com.android.webview com.google.android.webview com.android.location.fused
  com.android.externalstorage com.android.mtp com.android.keychain com.android.se
  'com.android.providers.settings' 'com.android.providers.media*' 'com.android.providers.downloads*'
  'com.android.providers.telephony' 'com.google.android.providers.media*'
  'com.mediatek.ims' 'com.mediatek.location*' com.mediatek.engineermode.protect
)
is_protected() {
  local p=$1 rule
  for rule in "${PROTECTED[@]}"; do
    if [[ $rule == *'*' ]]; then [[ $p == ${rule%\*}* ]] && return 0
    else [[ $p == "$rule" ]] && return 0; fi
  done
  return 1
}

home=$(adb shell cmd package resolve-activity --brief -a android.intent.action.MAIN \
        -c android.intent.category.HOME | tr -d '\r' | tail -1)
mkdir -p "$dir/apks"
rc=0
for p in "$@"; do
  if is_protected "$p"; then echo "REFUSED  $p (core package)"; rc=1; continue; fi
  if [[ $home == "$p/"* ]]; then
    echo "REFUSED  $p is the current Home app. Set another home first (cmd package set-home-activity)."
    rc=1; continue
  fi
  path=$(adb shell pm path "$p" | tr -d '\r' | head -1 | sed 's/^package://')
  [[ -n $path ]] || { echo "SKIP     $p (not installed)"; continue; }
  [[ -f "$dir/apks/$p.apk" ]] || adb pull "$path" "$dir/apks/$p.apk" >/dev/null 2>&1 \
    || echo "  (could not save APK for $p; install-existing will still restore it)"
  if [[ $mode == disable ]]; then out=$(adb shell pm disable-user --user 0 "$p" | tr -d '\r')
  else out=$(adb shell pm uninstall -k --user 0 "$p" | tr -d '\r'); fi
  echo "$mode  $p: $out"
  if [[ $out == *Success* || $out == *disabled* ]]; then
    grep -qx "$mode $p" "$dir/removed_packages.txt" || echo "$mode $p" >> "$dir/removed_packages.txt"
  else rc=1; fi
done
(cd "$dir/apks" && shasum -a 256 *.apk > SHA256SUMS 2>/dev/null) || true
exit $rc
