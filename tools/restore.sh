#!/usr/bin/env bash
# Undo tools/remove.sh.
# Usage: tools/restore.sh <backup-dir>            -> restore everything recorded in removed_packages.txt
#        tools/restore.sh <backup-dir> <pkg> ...  -> restore only these
set -uo pipefail
[[ $# -ge 1 ]] || { echo "usage: $0 <backup-dir> [pkg ...]"; exit 2; }
dir=$1; shift
list="$dir/removed_packages.txt"

restore_one() {
  local p=$1 mode
  mode=$(awk -v p="$p" '$2==p {print $1}' "$list" 2>/dev/null | tail -1)
  echo "Restoring $p"
  if [[ $mode == disable ]]; then
    adb shell pm enable --user 0 "$p"
  else
    adb shell cmd package install-existing --user 0 "$p" \
      || { echo "  install-existing failed, installing saved APK"; adb install -r "$dir/apks/$p.apk"; }
  fi
}

if [[ $# -gt 0 ]]; then pkgs=("$@")
else pkgs=(); while IFS= read -r p; do pkgs+=("$p"); done < <(grep -v '^#' "$list" | awk 'NF {print $2}'); fi
[[ ${#pkgs[@]} -gt 0 ]] || { echo "Nothing recorded in $list"; exit 0; }

for p in "${pkgs[@]}"; do [[ -n $p ]] && restore_one "$p"; done

# Put the original Home app and accessibility services back if they were captured.
orig_home=$(tail -1 "$dir/home_default.txt" 2>/dev/null | tr -d '\r')
if [[ $orig_home == */* ]] && printf '%s\n' "${pkgs[@]}" | grep -qx "${orig_home%%/*}"; then
  echo "Setting Home back to $orig_home"
  adb shell cmd package set-home-activity --user 0 "$orig_home"
  acc=$(tr -d '\r' < "$dir/accessibility_services.txt" 2>/dev/null)
  if [[ -n $acc && $acc != null ]]; then
    adb shell settings put secure enabled_accessibility_services "'$acc'"
    adb shell settings put secure accessibility_enabled 1
  fi
fi
echo "Done. Reboot recommended: adb shell sync; sleep 15; adb reboot"
