#!/usr/bin/env bash
# Snapshot the device before changing anything.
# Usage: tools/backup.sh [backup-dir]     (default: ./backup-YYYYMMDD-HHMM)
set -euo pipefail
dir=${1:-backup-$(date +%Y%m%d-%H%M)}
mkdir -p "$dir/apks"
adb get-state >/dev/null

sh() { adb shell "$@" | tr -d '\r'; }

echo "Backing up to $dir"
sh pm list packages -f                 > "$dir/packages_all_full.txt"
sh pm list packages -s | sed 's/^package://' | sort > "$dir/packages_system.txt"
sh pm list packages -3 | sed 's/^package://' | sort > "$dir/packages_user.txt"
sh pm list packages -d | sed 's/^package://' | sort > "$dir/packages_disabled.txt"
sh pm list packages -u | sed 's/^package://' | sort > "$dir/packages_incl_uninstalled.txt"
sh getprop                             > "$dir/getprop.txt"
for ns in system secure global; do sh settings list "$ns" > "$dir/settings_${ns}.txt"; done
sh cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME \
  > "$dir/home_default.txt"
sh cmd package query-activities --brief -a android.intent.action.MAIN -c android.intent.category.HOME \
  > "$dir/home_candidates.txt"
sh settings get secure enabled_accessibility_services > "$dir/accessibility_services.txt"
sh cmd notification list_listeners 2>/dev/null > "$dir/notification_listeners.txt" || true

# Records of what tools/remove.sh does land here.
touch "$dir/removed_packages.txt"
echo "Done. Default home: $(tail -1 "$dir/home_default.txt")"
echo "Keep this folder: tools/restore.sh $dir undoes everything tools/remove.sh records in it."
