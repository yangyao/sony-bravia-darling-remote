# Sony BRAVIA × DARLING Remote

English | [简体中文](README.md)

**An affordable, aluminum-body remote for your Sony TV.**

With kids at home, remotes end up on the floor. Some third-party Sony replacements I bought had fragile plastic shells and needed replacing after a few drops. Repeatedly buying replacements was frustrating, but I did not want to spend much more on an original Sony remote.

I found an inexpensive DARLING Bluetooth remote with an aluminum-alloy body. It was not made specifically for Sony TVs, but it could pair directly with mine. This project fixes its missing button mappings and shares that setup with people looking for a reasonably priced metal-body alternative.

**Direct Bluetooth connection · Native power and volume · Working OK, Back and Menu · No hardware modifications**

## Fewer replacement remotes

This is a replacement setup already used at home: physical buttons, an aluminum body, and no extra bridge or development board. It is intended for families like mine who keep replacing plastic remotes and want to stay within a budget.

The repository provides compatibility files and instructions for people who own this type of remote or are looking for a similar replacement. The aluminum shell is why I chose it; there are no drop-test results, and buttons, battery condition and connection reliability still need practical checks.

## Everyday controls

| Control | Current behavior |
| --- | --- |
| Power | Tested by the user; works without remapping |
| Direction pad, Home and volume | Work natively |
| OK and Back | Work after installing the layout |
| Three-line Menu button | Opens the current app's menu after installing the layout |
| Sony picture and sound Quick Settings | Not implemented; separate from an app menu |
| Laser pointer and left target-symbol buttons | Outside this project's TV controls |

During video playback, Menu can open an app's episode selection, quality or subtitle options. The player determines what is available.

After setup, the remote talks directly to the TV over Bluetooth. **No computer, ESP32, background remapping service or accessibility service is needed for daily use.**

## Tested hardware

| Device | Verified details |
| --- | --- |
| TV | Sony XR-65X90J, Chinese-market VH2 platform |
| System | Android 12 / API 31, firmware 682241 |
| Remote | Gold DARLING, aluminum-alloy body, rechargeable lithium battery, Micro-USB and laser pointer |
| Bluetooth name | `tKEY` on the TV; `tKeybd` on macOS |

The exact remote model is still unknown. **Branding or appearance alone does not establish compatibility.** Only this TV, firmware and remote combination has been tested; other models require separate verification.

## Get started

1. **Check that the remote pairs with your TV.** Use Add accessory in the TV settings, and disconnect it from other hosts first. A dedicated pairing-button combination has not been confirmed.
2. **Install the compatibility files.** Download the APK and setup helper from [Releases](https://github.com/yangyao/sony-bravia-darling-remote/releases), then follow the [installation guide](docs/setup.en.md) to install and select the layout over ADB. This step needs a computer, but no root access.
3. **Disconnect the computer and use the remote.** Test OK, Back and the app menu. These worked after the temporary computer-side key bridge was stopped.

The APK lets Android map the buttons directly. It does not modify the system partition or flash the remote. The selected layout survives Bluetooth reconnection; **persistence across a full TV reboot has not yet been tested**.

[Installation, removal and building from source →](docs/setup.en.md)

## Before buying one

This sample has shown Bluetooth disconnections and unreliable reconnection after idle periods. Moving closer to the TV and pressing Home has restored operation, but the cause is not established. Volume Down also intermittently failed without lighting the indicator, then later produced normal events, suggesting a possible contact problem.

This project fixes **button compatibility**. It cannot guarantee the hardware condition or wireless reliability of another used remote. Check pairing, operation at your normal viewing distance, buttons and battery condition before relying on one as your main remote.

## Why an APK is needed

The remote already sends standard Bluetooth HID input. The tested TV selects a system layout that omits its OK, Back and Menu buttons. A small keyboard-layout APK supplies those mappings:

```text
DARLING remote ──Bluetooth HID──► Sony BRAVIA
                                  Android loads the button layout
```

No ESP32 sits between the remote and TV. An ESP32-S3 was used only for early scanning and connection experiments. See the [investigation notes](docs/investigation.en.md) and [key data](docs/keymap.json) for details.

## Repository structure

| Directory | Contents |
| --- | --- |
| `android-layout/` | OK, Back and Menu layout APK, plus a one-shot setup helper |
| `tools/` | Install/remove scripts and a macOS HID inspection tool |
| `docs/` | Chinese and English setup guides, investigation notes and key data |

## License

[MIT](LICENSE). Not affiliated with Sony or DARLING.
