# The prompt

Paste everything below the line into Claude Code (or another coding assistant with shell access) on a
computer with `adb` installed, after cloning this repo and opening that folder in the assistant.
Written for the **KONKR Pocket Block** (Android 12, MediaTek), and it works on most Android handhelds
with a vendor launcher: the assistant discovers what is on *your* device and asks before touching anything.

Before you start, on the handheld: Settings → About device → tap **Build number** seven times → back →
System → Developer options → **USB debugging** on. Plug it into your computer with a data-capable USB-C cable.

This guide only customises the device you own with standard Android tooling (`adb`, `pm`, `settings`).
It does not unlock the bootloader, root the device, or use any vendor debug binaries, and the assistant is
told not to.

---

I want to clean up my Android gaming handheld and set it up as a dedicated retro-gaming device.
My device is: <MODEL HERE, e.g. KONKR Pocket Block>. My computer runs: <macOS / Windows / Linux>.

Work on the real device over USB with `adb`, one step at a time. **Before each step, tell me in a
sentence or two what it does, show me the choices, and wait for my answer.** Verify every change on the
device (package lists, `dumpsys`, and a screenshot with `adb exec-out screencap -p` when something
visual changed). Reuse the scripts in this repo's `tools/` folder rather than writing your own; if a file
named here is missing, you are not in the repo: clone `https://github.com/cgogoel/cleanyourblock` and work
from there. Read `devices/` for a file matching my model first: it lists what was found on that device before.

Ground rules
- Customise only. Do not unlock the bootloader, flash partitions, root, or use any setuid/`su`-style
  binary you find on the firmware, even if it would make a step easier. If a step can't be done without
  that, tell me and skip it.
- Never delete anything from `/system`. Remove apps only with `pm uninstall -k --user 0` (reversible
  with `cmd package install-existing`) or `pm disable-user --user 0`, and only through `tools/remove.sh`,
  which refuses core Android packages and keeps a restore record.
- Run `pm` commands one per shell call; chained ones can stop silently after the first.
- Don't launch packages with factory, aging, test, or logger in the name to "see what they do": use
  `dumpsys package <name>` instead.
- Never type my Google password, Patreon login, or any credential anywhere. If something needs a
  login, I'll do it on the device.
- When I give you files (APKs, ROMs, BIOS), only use the paths I give you. Don't download ROMs or BIOS
  files from the internet, and don't suggest where to get them.

## Step 0 — Connect
- Run `adb devices`. Tell me when the "Allow USB debugging?" prompt will appear so I can tick
  "Always allow from this computer" and accept.
- Report the model, Android version and free storage (`getprop ro.product.model`,
  `getprop ro.build.version.release`, `df -h /sdcard`), and list any SD card under `/storage`.
- Check `getprop service.adb.tcp.port`. If it is set (often `5555`), tell me: it means adb is
  listening on my Wi-Fi network too, not only USB. Offer to close it for this boot with `adb usb`
  (this restarts adb, so reconnect afterwards), and remind me again at the end.

## Step 1 — Back up
Run `tools/backup.sh` (it writes to `./backup-<date>/`): package lists (all, system, user, disabled),
`getprop`, all three `settings` namespaces, the current Home app and launcher candidates, and the APK of
every package before it is removed. Then ask me:
- "Do you also want a copy of your user storage (ROMs, ES-DE/RetroArch folders, saves, screenshots)
  pulled to this computer?" If yes, show me the folder sizes under `/sdcard` first, ask which ones, and
  pull only those with `adb pull`.

## Step 2 — Decide what to remove / keep
List every installed package (`pm list packages -f`) and sort it into a table with these groups:
1. **Vendor launcher and its services** (e.g. AYAHome / `com.ayaneo.home`)
2. **Vendor OTA / update client** (e.g. Adups `com.adups.fota`)
3. **Factory, test and debug tools** (aging test, factory test, logger UI, traceur)
4. **Vendor "optimisers"** (e.g. MediaTek DuraSpeed)
5. **Google extras** (Photos Go, Files, Feedback, Restore, Location History, Chrome)
6. **Small Android extras** (screensaver "dreams", bookmark providers, Bluetooth MIDI, Dynamic System Updates)
7. **Keep: needed to work** (Settings, SystemUI, keyboard, Play Store/Services, Bluetooth, permission
   controller, package installer, Launcher3 as a fallback home, documents UI, etc.)

For each package give one line on what it does and a recommendation, using `devices/<model>.md` where it
has one. Then ask me **which to remove and which to keep** as a checklist, with groups 1–4 pre-ticked
and 5–6 left for me to choose. Explain these consequences before I answer:
- Removing the **vendor launcher** (AYAHome on the Pocket Block) also removes what drives the extra
  buttons (Home/guide, and the shoulder-side/back buttons). They stop doing anything until mapped
  again in Step 5. It also removes the vendor's controller/performance settings UI.
- Removing the **OTA client** means no more firmware updates until restored. Say so plainly and let me decide.
- Never offer groups 7 or anything `tools/remove.sh` refuses.

Then, in small batches (3–5 packages), run `tools/remove.sh <backup-dir> <pkg> ...`, check
`pm list packages` after each batch, and screenshot. Don't remove the current Home app until Step 3
has a replacement set as default.

## Step 3 — Choose the frontend (home screen)
Ask me which frontend I want as the device's home screen, and how I have it:

| Frontend | How you get it | Notes |
|---|---|---|
| **ES-DE** (Patreon build) | I give you the `.apk` path on this computer | Sideload with `adb install`. Package is usually `org.es_de.frontend`. |
| **ES-DE** (Play Store build) | I install it from Play on the device | Same app, store-managed updates. |
| **Daijishō** | Play Store on the device | Free, per-platform folder setup inside the app. |
| **Another frontend** I already have (Beacon, Pegasus, iiSU, Console Launcher, …) | APK path or already installed | Tell me its name. |
| **No frontend**, keep stock Launcher3 | nothing | Launcher3 stays as home. |

Then:
- Install it if I gave you an APK (`adb install -r <path>`; if that hangs, push to `/data/local/tmp` and
  `pm install -r` from the shell). If it comes from Play, wait while I install it and tell you.
- Find its HOME activity with
  `cmd package query-activities --components -a android.intent.action.MAIN -c android.intent.category.HOME`.
  If it isn't listed, it can't be the default home: tell me and offer to keep Launcher3 as home with the
  frontend pinned on it instead.
- Set it with `cmd package set-home-activity --user 0 <component>`, press Home
  (`input keyevent KEYCODE_HOME`) and screenshot to prove it.
- Keep Launcher3 installed as the fallback home so a crashed frontend never leaves a black screen.
- Ask whether I also want **RetroArch** (and which build: the Play Store one, or the `aarch64` APK from
  libretro that I give you the path to) and any standalone emulators I have APKs for. Install those I name.
- Now that a new home is default, finish removing the old vendor launcher if I ticked it in Step 2.

## Step 4 — Transfer my ROMs
Ask me:
1. Where my ROM folder is on this computer (path).
2. Internal storage or SD card on the device (show both with free space).
3. The folder layout. For **ES-DE**, use its system folder names (`ROMs/snes`, `ROMs/gba`, `ROMs/psx`, …):
   if ES-DE is already set up, list the existing `ROMs/` subfolders on the device and map my local folders
   to them; if not, open ES-DE once on the device to let it create the ROM directory, then check it. For
   **Daijishō** or another frontend, ask what layout I want (one folder per system is fine) and remind me
   to point each platform at it in the app afterwards.

Show me a mapping table (local folder → device folder, file count, size) and the total against free space,
and only continue when I confirm. Then run `tools/push-roms.sh <local-dir> <device-dir>` for each mapping:
it skips macOS metadata (`._*`, `.DS_Store`), uses `adb push --sync` so re-runs only send what changed, and
compares file counts at the end. If I have BIOS files, ask me which emulator/frontend expects them where
(RetroArch: `RetroArch/system/`) and push only the ones I point you at.
Afterwards, tell me to re-scan in the frontend (ES-DE: Start → Utilities / restart; Daijishō: re-sync platforms).

Only transfer games I tell you I own; if I ask where to find ROMs, decline that part.

## Step 5 — Optional: remap the extra buttons with Key Mapper
Ask whether I want this. If I removed the vendor launcher, the extra buttons are dead without it.

- Install **Key Mapper** (`io.github.sds100.keymapper`) from F-Droid, Play, or the GitHub release APK
  I give you. Ask which.
- Identify the buttons: run `adb shell getevent -lq` for 20 seconds while I press each extra button
  in turn, and tell me which input device and key code each one is. On the Pocket Block these are on
  `odm:gpio_keys` (raw codes `0x2f0`, `0x2f1`, `0x2f2`) and the guide/Home button on the
  `AYANEO Controller` (`BTN_MODE`).
- Ask me **what I want each button to do** (Home, Back, Recents, screenshot, volume, brightness up/down,
  launch an app, toggle a setting, …).
- Walk me through Key Mapper on the device: grant its accessibility service when it asks
  (Settings → Accessibility → Key Mapper), create one mapping per button by pressing the button when
  it says "record trigger", then the action. You can open screens with `am start` but I tap the toggles.
- Test each mapping and screenshot the Key Mapper list.

### Optional: Expert Mode (only if a button can't be mapped normally)
Some buttons are handled by Android before any app sees them. On the Pocket Block that is the guide
button: Android treats it as `BUTTON_MODE`/Home, so a normal mapping can't override it. Key Mapper's
**Expert Mode** can, by reading input directly through a helper process started over adb.

Before setting it up, explain these caveats and ask me to confirm:
- **It doesn't survive a reboot.** The helper has to be started from a computer over USB after every
  restart (`tools/keymapper-expert.sh`). Until then that button does its default action again.
- **USB debugging has to stay on** for that. Anything that can reach adb can control the device, so
  revoke authorisations on computers you don't own and don't plug into untrusted PCs/chargers with data.
- **Some firmware also opens adb on the network at every boot** (the Pocket Block sets port 5555).
  Combined with USB debugging left on, that means anyone on the same Wi-Fi could try to connect.
  `tools/keymapper-expert.sh` closes the network port each time it runs, but it reopens on the next
  reboot until you run the script again. Prefer trusted networks, and turn USB debugging off whenever you
  decide you can live without the remapped button.
- Expert Mode needs Key Mapper ≥ 3.x; the exact start command is shown on its Expert Mode setup screen.
  If that command differs from what `tools/keymapper-expert.sh` runs, use the app's and tell me.

If I confirm: enable Expert Mode in Key Mapper's settings, run `tools/keymapper-expert.sh`, record the
guide-button trigger again with Expert Mode on, and test it. If I say no, leave that button on its default.

## Step 6 — Finish and lock down
- Reboot (`adb shell sync`, wait 15 seconds, `adb reboot`), and check after boot: the home is my chosen
  frontend, removed packages are still gone (`pm list packages | grep <name>`), mappings work.
- Check `getprop service.adb.tcp.port` again. If it is set and I didn't choose Expert Mode, tell me to
  turn **USB debugging off** in Developer options when we're done (that closes both).
- Write `backup-<date>/SUMMARY.md`: device, what was removed and kept, the frontend and home component,
  ROM folders transferred, button mappings, Expert Mode yes/no, and the one-line restore command:
  `tools/restore.sh backup-<date>` (or `tools/restore.sh backup-<date> <pkg>` for one package).
- Offer to write a `devices/<model>.md` in the same format as the Pocket Block one so others benefit,
  **without** serial numbers, IMEI, MAC addresses, Wi-Fi names, or account names.

## Optional — Check what's still phoning home
If I ask: run `tools/netcheck.sh 600 ./netcheck` for ten minutes while I use the device normally, then
`python3 tools/netcheck_report.py ./netcheck/sockets_raw.txt ./netcheck/uid_map.txt` and show me a table of
which app talked to which address. Note its limits: without root, connections shorter than the 2-second
sample can be missed and DNS names aren't visible. Use `whois` only on the IPs, never send my device
details anywhere.
