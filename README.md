# CleanYourBlock

> **Why this exists.** I work in the Android/iOS security space and have seen what gets left on some
> Android devices when they ship to consumers. Sometimes it's a factory test app that leaves some holes
> open, sometimes it's blatant malware in an Android TV box, and sometimes it's a firmware updater
> (*cough* ADUPS) that tracks, logs, and has remote command and control from the country of origin. My
> colleague exposed the ADUPS firmware OTA issues in a BLU phone sold through Amazon in 2016, and I found
> that my KONKR Pocket Block (an Ayaneo brand) was also using the same provider. The threat model is vastly
> different, as this device won't have a SIM or be used for most of my personal services, but I still
> don't want that on a device that may connect to my home network and travel with me. This is a first go
> at a [cleanyourtv](https://github.com/Gathin23/cleanyourtv)-style repo for removing the OEM software from
> these devices and sticking to FOSS or paid software that I opt in to.
>
> **⚠️ A warning.** I found a fun "feature" while creating this prompt: by default the device opens
> network ADB on port 5555 at every boot, separate from Android's Wireless debugging setting. That means
> if you leave USB Debugging on while you're connected to a network, anyone on the same network can
> connect and request access; a computer you've already approved gets in with no prompt, and one
> mis-tapped "Allow" hands over full control. This is built into the system software and can't be
> disabled permanently, only on each reboot. So be careful: **disable USB Debugging after you finish
> customizing**, or only connect the device to Wi-Fi in trusted spaces.

**Turn a KONKR Pocket Block (or a similar Android handheld) into a clean, quiet retro-gaming device,
guided step by step by a coding assistant.** Strip the vendor launcher, OTA client and factory junk,
set the frontend you want as home, copy your ROMs over from your computer, and remap the extra buttons.

No root, no bootloader unlock, nothing deleted from `/system`, and a one-line restore.

Inspired by [cleanyourtv](https://github.com/Gathin23/cleanyourtv), same idea for a handheld.

## How it works

| Step | What happens | You decide |
|---|---|---|
| **0. Connect** | `adb` over USB, checks model, storage and whether adb is also open on the network | — |
| **1. Back up** | Package lists, settings, current home, and each APK before it goes | Whether to also pull your user storage |
| **2. Remove / keep** | Sorts every package into groups with a one-line explanation | Which to remove and which to keep |
| **3. Frontend** | Installs and sets your frontend as the Home app; Launcher3 stays as fallback | ES-DE (Patreon APK or Play), Daijishō, another frontend, or none; RetroArch build |
| **4. ROMs** | Maps your computer's ROM folders to the frontend's layout, checks space, copies with `adb push --sync` | Source folder, internal vs SD, folder mapping |
| **5. Buttons** *(optional)* | Key Mapper for the extra buttons; Expert Mode for the guide button, with caveats | What each button does; whether Expert Mode is worth it |
| **6. Finish** | Reboot check, summary, restore command, reminder to turn USB debugging off | — |

The assistant asks before each step and verifies on the device.

## Quick start

1. **On the handheld:** Settings → About device → tap **Build number** 7 times → Developer options →
   **USB debugging** on. Connect it to your computer by USB-C.
2. **On your computer:** install [Android platform-tools](https://developer.android.com/tools/releases/platform-tools)
   (`brew install android-platform-tools` on macOS), then:
   ```bash
   git clone https://github.com/cgogoel/cleanyourblock
   ```
3. Open the folder in Claude Code (or Codex / Gemini CLI), paste [`PROMPT.md`](PROMPT.md), fill in your
   model, and answer its questions.

Have ready: your frontend APK if you're sideloading one (e.g. the ES-DE Patreon build), and the path to
your ROM folder. ROMs and BIOS files are yours to provide: this project doesn't help find them.

## Tools

You can also run these yourself (macOS / Linux / WSL; Windows users can let the assistant run the
equivalent `adb` commands):

| Script | What it does |
|---|---|
| `tools/backup.sh [dir]` | Snapshot packages, settings, home app |
| `tools/remove.sh <dir> <pkg>...` | `pm uninstall -k --user 0` with APK backup and a record; refuses core packages and the current home. `MODE=disable` uses `pm disable-user` instead |
| `tools/restore.sh <dir> [pkg...]` | Bring back everything (or some) packages, the original home and accessibility services |
| `tools/push-roms.sh <local> <device>` | Copy a ROM folder, skipping `._*`/`.DS_Store`, resumable. `DRY_RUN=1` to preview |
| `tools/keymapper-expert.sh` | Start Key Mapper's Expert Mode helper after a reboot and close network adb |
| `tools/netcheck.sh` + `netcheck_report.py` | Optional: see which apps connect where |

## Undo

```bash
tools/restore.sh backup-YYYYMMDD-HHMM
```

Then `adb reboot`. Packages removed with `--user 0` stay on the system partition, so `install-existing`
restores them exactly; a factory reset also brings everything back.

## Expert Mode, in short

The guide button on the Pocket Block is handled by Android before apps see it, so only Key Mapper's
Expert Mode can remap it. That needs a helper started over USB **after every reboot**, which means
leaving **USB debugging on**, and this firmware also opens adb on your Wi-Fi at every boot. The script
closes that each time it runs. If that trade-off isn't worth one button, skip it: the other three
buttons remap without it. Details in [`PROMPT.md`](PROMPT.md#optional-expert-mode-only-if-a-button-cant-be-mapped-normally).

## Devices

- [KONKR Pocket Block](devices/konkr-pocket-block.md): package list, buttons, firmware notes

Other Android handhelds should work, since the prompt discovers packages on your device. PRs with a
`devices/<model>.md` are welcome (no serials, MACs or account names).

## Not covered

Bootloader unlocking, rooting, flashing, or using vendor debug binaries. This guide customises what
the device already lets its owner change.

## License

MIT
