#!/usr/bin/env bash
# Copy a local ROM folder to the device, skipping macOS metadata. Re-runs only send changed files.
# Usage: tools/push-roms.sh <local-dir> <device-dir>
#   e.g. tools/push-roms.sh ~/Games/SNES /sdcard/ROMs/snes
#        tools/push-roms.sh ~/Games/GBA  /storage/1234-ABCD/ROMs/gba
# DRY_RUN=1 lists what would be sent without sending it.
set -uo pipefail
[[ $# -eq 2 ]] || { echo "usage: $0 <local-dir> <device-dir>"; exit 2; }
src=${1%/}; dst=${2%/}
[[ -d $src ]] || { echo "Not a folder: $src"; exit 2; }

files=()
while IFS= read -r -d '' f; do files+=("$f"); done < <(
  find "$src" -type f ! -name '._*' ! -name '.DS_Store' ! -name 'Thumbs.db' ! -path '*/.Spotlight-V100/*' \
       ! -path '*/.Trashes/*' -print0)
n=${#files[@]}
[[ $n -gt 0 ]] || { echo "No files found in $src"; exit 1; }
bytes=$(printf '%s\0' "${files[@]}" | xargs -0 stat -f%z 2>/dev/null | awk '{s+=$1} END {print s+0}')
[[ $bytes == 0 ]] && bytes=$(printf '%s\0' "${files[@]}" | xargs -0 stat -c%s 2>/dev/null | awk '{s+=$1} END {print s+0}')
free=$(adb shell df -k "$(dirname "$dst")" 2>/dev/null | tr -d '\r' | awk 'NR==2 {print $4*1024}')
printf '%s -> %s : %d files, %.1f MB (device free: %.1f MB)\n' "$src" "$dst" "$n" \
  "$(echo "$bytes/1048576" | bc -l)" "$(echo "${free:-0}/1048576" | bc -l)"
if [[ -n $free && $bytes -gt $free ]]; then echo "Not enough space on the device."; exit 1; fi
[[ ${DRY_RUN:-0} == 1 ]] && { printf '  %s\n' "${files[@]#$src/}"; exit 0; }

adb shell mkdir -p "\"$dst\""
fail=0; i=0
for f in "${files[@]}"; do
  i=$((i+1)); rel=${f#$src/}; d=$(dirname "$rel")
  [[ $d != . ]] && adb shell mkdir -p "\"$dst/$d\"" >/dev/null
  printf '[%d/%d] %s\n' "$i" "$n" "$rel"
  adb push --sync "$f" "$dst/$rel" >/dev/null || { echo "  FAILED"; fail=$((fail+1)); }
done

remote=$(adb shell "find \"$dst\" -type f ! -name '._*' | wc -l" | tr -d '\r ')
echo "Local files: $n   On device under $dst: $remote   Failed: $fail"
[[ $fail -eq 0 ]]
