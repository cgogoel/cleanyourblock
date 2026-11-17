#!/usr/bin/env bash
# Sample the device's socket tables (with owning UID) every 2 s and stream logcat. No root needed.
# Usage: tools/netcheck.sh <seconds> <outdir>     then: python3 tools/netcheck_report.py <outdir>/sockets_raw.txt <outdir>/uid_map.txt
set -uo pipefail
dur=${1:-600}; out=${2:-netcheck}; mkdir -p "$out"
adb logcat -c 2>/dev/null
adb logcat -b main,system,events,crash -v threadtime > "$out/logcat.txt" 2>&1 &
lc=$!
trap 'kill $lc 2>/dev/null' EXIT
end=$(( $(date +%s) + dur ))
echo "Capturing for $dur s. Use the device normally."
while (( $(date +%s) < end )); do
  ts=$(date '+%Y-%m-%dT%H:%M:%S')
  adb shell 'for f in tcp tcp6 udp udp6; do sed "1d;s/^/$f /" /proc/net/$f; done' 2>/dev/null \
    | awk -v ts="$ts" '{print ts, $0}' >> "$out/sockets_raw.txt"
  sleep 2
done
adb shell dumpsys netstats detail > "$out/netstats.txt" 2>&1
adb shell cmd package list packages -U | sed 's/package://' | tr -d '\r' > "$out/uid_map.txt"
echo "Capture finished: $out"
