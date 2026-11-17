#!/usr/bin/env bash
# Start Key Mapper's Expert Mode helper. Run this after every reboot of the device.
# Read the caveats in PROMPT.md (Step 5) before relying on it: it needs USB debugging left on.
#
# Usage: tools/keymapper-expert.sh
# START_CMD overrides the helper command if Key Mapper's Expert Mode screen shows a different one.
set -uo pipefail
START_CMD=${START_CMD:-sh /storage/emulated/0/Android/data/io.github.sds100.keymapper/start.sh}

adb wait-for-usb-device

# Some firmware (the KONKR Pocket Block among them) turns on network adb (TCP 5555) at every boot.
# Switch adbd back to USB-only first; this restarts adbd, so it has to happen before the helper starts.
port=$(adb shell getprop service.adb.tcp.port | tr -d '\r')
if [[ -n $port && $port != 0 ]]; then
  echo "Network adb is on (port $port); switching adb back to USB only"
  adb usb; sleep 2; adb wait-for-usb-device; sleep 2
fi

adb shell pm path io.github.sds100.keymapper >/dev/null 2>&1 \
  || { echo "Key Mapper (io.github.sds100.keymapper) is not installed."; exit 1; }

adb shell "$START_CMD" | tail -1
sleep 3
adb shell settings put global adb_wifi_enabled 0   # keep Wireless debugging off

port=$(adb shell getprop service.adb.tcp.port | tr -d '\r')
if [[ -z $port || $port == 0 ]]; then echo "Network adb off (closed until next reboot)"
else echo "WARNING: network adb still on (port $port)"; fi
echo "Expert Mode helper started. If a mapped button still does its default action, open Key Mapper once."
