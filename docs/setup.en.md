# Installation and development

English | [简体中文](setup.md) | [Back to overview](../README.en.md)

## Requirements

Tested with a Chinese-market Sony XR-65X90J, Android 12, firmware 682241, and a directly paired DARLING BLE HID remote reporting VID `0x248A` / PID `0x8266`. Other combinations need separate verification. The IDs do not establish the chip model.

Pair the remote using Add accessory on the TV first. Verify native directions, Home or volume. Disconnect other Bluetooth hosts and stop any development-board connection attempts. A dedicated pairing combination is still unknown.

Install Android Platform Tools on a computer, then enable and authorize ADB on the TV. The APK has no launcher screen; installing it alone does not select the layout.

## Install a release

1. Clone the repository for the scripts.
2. Download `darling-tv-layout.apk`, `layout-control.jar` and `SHA256SUMS` from [Releases](https://github.com/yangyao/sony-bravia-darling-remote/releases) into one directory.
3. Keep the remote connected to the TV. Replace `TV_IP:5555` with the actual serial shown by `adb devices`, and replace the download path:

```sh
git clone https://github.com/yangyao/sony-bravia-darling-remote.git
cd sony-bravia-darling-remote
adb connect TV_IP:5555
adb devices
sh tools/install-layout.sh TV_IP:5555 /path/to/downloaded-files
```

Run `shasum -a 256 -c SHA256SUMS` in the download directory to verify release files.

The installer reads the original layout and prints `BEFORE` and `AFTER`. Save the original layout ID if `BEFORE` is not `null`. It then installs the APK and selects the layout using a one-shot helper. No key-forwarding process remains running.

Disconnect the computer's ADB connection and test OK, Back and the three-line Menu button. Directions, Home, volume and power retain their native behavior.

## Implementation

The tested TV assigns this VID/PID to `Vendor_0957_Product_0001.kl`, which omits three Linux input codes:

| Input | Linux scan code | Added Android mapping |
| --- | --- | --- |
| Keypad Enter | 96 | `DPAD_CENTER` |
| Esc | 1 | `BACK` |
| Application/Menu (`KEY_COMPOSE`) | 127 | `MENU` |

The APK provides this KCM:

```text
type OVERLAY
map key 96 DPAD_CENTER
map key 1 BACK
map key 127 MENU
```

Android 12 can load the overlay from the APK. On the tested TV, ADB shell has the `SET_KEYBOARD_LAYOUT` permission needed to select it. No `/system` writes, root access, accessibility service or background listener are required.

Layout ID:

```text
local.darling.keylayout/local.darling.keylayout.LayoutsReceiver/darling_tv
```

## Inspect and remove

The installer puts the helper in `/data/local/tmp` on the TV. With the remote connected, inspect the current layout:

```sh
adb -s TV_IP:5555 shell 'CLASSPATH=/data/local/tmp/darling-layout-control.jar app_process /system/bin LayoutControl'
```

Remove the layout selection and uninstall the APK:

```sh
sh tools/remove-layout.sh TV_IP:5555 /path/to/downloaded-files
```

The original selection on the tested TV was `null`. If yours had another custom layout, reselect the ID saved during installation:

```sh
adb -s TV_IP:5555 shell 'CLASSPATH=/data/local/tmp/darling-layout-control.jar app_process /system/bin LayoutControl apply ORIGINAL_LAYOUT_ID'
```

Replace `ORIGINAL_LAYOUT_ID` with the saved value. Removal does not modify the system partition.

## Build from source

Requires a JDK supporting `javac --release 8`, Android SDK Platform 34, Build Tools 35.0.1 and `zip`:

```sh
export JAVA_HOME=/path/to/jdk
export ANDROID_SDK_ROOT=/path/to/android-sdk
sh android-layout/build.sh
sh tools/install-layout.sh TV_IP:5555
```

Outputs are `android-layout/build/darling-tv-layout.apk` and `layout-control.jar`. Override tool paths with `DARLING_BUILD_TOOLS`, `DARLING_ANDROID_JAR` or `DARLING_JAVA_BIN`.

The first build creates a local signing key in the ignored `build/` directory with the development password `android`. Keep it for updates, and do not use it for other products. Keys and build outputs are excluded from Git. If your signature differs from the installed APK, uninstall that version before installing and selecting your own layout.

## Verification scope

- OK and Back worked after the computer-side bridge stopped; the app Menu was also confirmed working.
- The user confirmed native power operation; its raw key code was not separately recorded.
- Layout selection remained after Bluetooth disconnection and reconnection.
- Persistence across a full TV reboot is expected but untested. Keep the layout APK installed so its resources remain available.
- Menu opens the current app's menu, not Sony Quick Settings.
- Other Android releases, including Android 14, may have different APIs and eligibility rules. This helper targets Android 12.

## References

- [AOSP Android 12: layout selection and persistence](https://android.googlesource.com/platform/frameworks/base/+/android-12.0.0_r1/services/core/java/com/android/server/input/InputManagerService.java)
- [AOSP: KCM parser](https://android.googlesource.com/platform/frameworks/native/+/android-12.0.0_r1/libs/input/KeyCharacterMap.cpp)
- [Sony X90J: Quick Settings](https://www.sony.com/electronics/support/televisions-projectors-lcd-tvs-android-/xr-65x90j/articles/00225435)
