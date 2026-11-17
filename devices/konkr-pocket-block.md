# KONKR Pocket Block

| | |
|---|---|
| SoC | MediaTek (`mt6768` platform) |
| Android | 12 |
| Stock home | AYAHome (`com.ayaneo.home`) |
| Controller | `AYANEO Controller` (vendor `4001`, product `0428`) + extra keys on `odm:gpio_keys` |
| Tested | November 2026, firmware `m8695_bw01_v01_20260327` |

## Packages

Removed on the reference device with `pm uninstall -k --user 0` (all restorable with `tools/restore.sh`):

| Package | What it is | Recommendation |
|---|---|---|
| `com.ayaneo.home` | AYAHome launcher, game window overlay, button handler, controller/perf settings UI | Remove once a frontend is home. Extra buttons stop working until remapped (Step 5). Talks to Ayaneo servers and Tencent Cloud/Bugly analytics endpoints. |
| `com.adups.fota` | Adups firmware-update client, identifies the device by serial number | Remove if you're fine without OTA updates (restore it before checking for one). |
| `com.mediatek.duraspeed` | MediaTek background-app "speed" manager | Remove |
| `com.android.agingtest` | Factory burn-in test | Remove. Don't launch it. |
| `com.android.factorytest` | Factory test menu | Remove. Don't launch it. |
| `com.debug.loggerui` | MediaTek debug logger | Remove |
| `com.android.traceur` | System tracing tool | Remove |
| `com.android.dreams.basic` | Screensaver | Remove |
| `com.android.providers.partnerbookmarks`, `com.android.bookmarkprovider` | Browser bookmark providers | Remove |
| `com.android.bluetoothmidiservice` | Bluetooth MIDI | Remove unless you use MIDI |
| `com.android.dynsystem` | Dynamic System Updates (GSI loader) | Remove |
| `com.google.android.feedback` | Google feedback reporter | Remove |
| `com.google.android.gms.location.history` | Google Location History | Remove |
| `com.google.android.apps.restore` | Google setup restore | Remove (only used at first setup) |
| `com.google.android.apps.photosgo` | Gallery Go | Your choice |

Considered and kept on the reference device:

| Package | Why kept |
|---|---|
| `com.android.launcher3` | Fallback home if the frontend crashes |
| `com.android.chrome` | Your choice; the only browser on the device |
| `com.google.android.apps.nbu.files` | Files by Google; handy for moving files without a computer |
| Play Store / Play Services / Gboard / WebView | Needed for apps and sign-in |

## Buttons

| Button | Input device | Code | Without AYAHome | Mapping |
|---|---|---|---|---|
| Extra button 1 | `odm:gpio_keys` | `0x2f0` | does nothing | Key Mapper (accessibility) |
| Extra button 2 | `odm:gpio_keys` | `0x2f1` | does nothing | Key Mapper (accessibility) |
| Extra button 3 | `odm:gpio_keys` | `0x2f2` | does nothing | Key Mapper (accessibility) |
| Guide / logo button | `AYANEO Controller` | `BTN_MODE` (316) | Android Home | Key Mapper **Expert Mode** only |

Confirm which physical button is which with `adb shell getevent -lq` on your unit.

## Firmware notes (read before leaving USB debugging on)

- The firmware sets `service.adb.tcp.port=5555` at every boot, so with USB debugging on, adb also
  listens on your Wi-Fi network. `adb usb` closes it until the next reboot; turning USB debugging off
  closes it for good. `tools/keymapper-expert.sh` runs `adb usb` for you.
- The firmware also ships a privileged debug binary reachable from an adb shell. Practical upshot for
  users: **anything that gets adb access to this device gets full control of it.** Treat USB debugging
  as off-by-default, and only leave it on if you've chosen Expert Mode and accepted that trade-off.
  This guide never uses that binary.
- Controller configuration nodes under `/sys/class/ayaneo_gamepad` are world-writable, so any app can
  change button swaps/turbo. Nothing to do about it without root; just be aware if buttons change on their own.

## Network after cleanup (20-minute capture)

With AYAHome and Adups removed, the only remote endpoints seen were Google (Play, Services, Gboard,
WebView), GitLab/Cloudflare (ES-DE update check), libretro/Cloudflare (RetroArch, plain HTTP) and an ad
network from a third-party gamepad-tester app. No Ayaneo, Adups, Tencent or other vendor endpoints.
