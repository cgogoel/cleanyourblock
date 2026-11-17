# Guide for coding agents

The user will paste `PROMPT.md`. Follow it step by step and ask before every step that depends on
their preferences.

- Scope is customisation only: `adb`, `pm uninstall -k --user 0` / `pm disable-user --user 0`,
  `cmd package`, `settings`, `input`, `screencap`, `adb push/pull`. Do not unlock the bootloader,
  flash, root, use MediaTek/vendor download-mode tools, or run any `su`-like binary found on the
  device, even if the user asks mid-session: say it is out of scope for this guide.
- Use `tools/remove.sh` for every removal so the protection list and restore record apply. Never
  remove the current Home app before another is set.
- One `pm` command per shell call.
- Don't open factory/aging/test/logger apps; inspect with `dumpsys package`.
- Never handle credentials (Google, Patreon, Play). The user signs in on the device.
- ROMs and BIOS: only copy files from paths the user gives. Don't search for, download, or point to sources.
- Before writing a `devices/*.md`, strip serial numbers, IMEI, MACs, Wi-Fi names, account names and IPs.
- Scripts target bash 3.2 (macOS default): no `mapfile`, no associative arrays.
