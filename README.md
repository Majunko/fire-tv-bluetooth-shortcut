# Bluetooth Devices — Fire TV Shortcut

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A tiny, **zero-UI** shortcut app for Amazon Fire TV that jumps straight to
**Settings → Controllers & Bluetooth Devices → Other Bluetooth Devices** —
the list of *already-paired* devices, where you just select one to connect.

No scanning is started, no window ever flashes. The app draws nothing:
it fires a deep link, finishes itself, and leaves no task behind.

## Why?

Pairing a Bluetooth device on Fire TV takes several menu hops. This puts a
single tile on your home row that opens the device list instantly — handy
for toggling headphones, controllers or speakers on and off.

## How it works

`MainActivity` uses `Theme.NoDisplay` and tries these intents in order:

| Priority | Intent | Screen |
|---|---|---|
| 1 | action `com.amazon.device.settings.action.INPUT_DEVICES` | **Other Bluetooth Devices** (paired list) ✅ |
| 2 | component `com.amazon.tv.settings.v2/.tv.controllers_bluetooth_devices.ControllersAndBluetoothActivity` | same activity, explicit |
| 3 | action `com.amazon.device.settings.action.HURLEY` | parent Controllers & Bluetooth Devices page |

> Note: the standard `android.settings.BLUETOOTH_SETTINGS` intent resolves to
> **nothing** on Fire OS 8 — the Amazon-specific actions above are required.

## Install

1. Enable **ADB debugging** on the Fire TV
   (*Settings → My Fire TV → Developer options*).
2. Connect and install:

   ```powershell
   adb connect <TV-IP>:5555
   adb install BluetoothShortcut.apk
   ```

3. Launch it from **Your Apps & Channels** (Fire OS lists sideloaded apps there).

The app is signed with a debug key, which is all Fire TV sideloading requires.

## Building from source

No Gradle needed — just the plain Android SDK command-line tools.

**Requirements (Windows PowerShell):**
- Android SDK with `build-tools 34.0.0` and a platform (`android-34` or `android-28`)
- JDK 17

Point `build.ps1` at your local JDK/SDK if the paths differ, then:

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1
# -> BluetoothShortcut.apk (signed with ~/.android/debug.keystore)
```

`build.ps1` also runs `make_art.ps1`, which **generates the app icon and the
leanback banner programmatically** (System.Drawing) into `res/` — no binary
art files are committed.

Pipeline: `javac → d8 → aapt2 compile/link → inject classes.dex → zipalign → apksigner`

## Project layout

```
AndroidManifest.xml                       # launcher + leanback launcher entry
src/com/majunko/btshortcut/MainActivity.java  # relay-and-finish logic
build.ps1                                 # full Gradle-free build
make_art.ps1                              # icon + banner generator
```

## Tested on

- Fire TV Stick 4K Max (2nd gen), Fire OS 8

## License

[MIT](LICENSE)
