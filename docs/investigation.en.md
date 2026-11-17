# Investigation notes

English | [简体中文](investigation.md) | [Back to overview](../README.en.md)

## From hardware modification to direct pairing

The initial idea was to identify and reflash the DARLING controller, or use an ESP32 to read buttons and bridge them to the TV. U1's markings could not be identified from the photo, and no SDK, firmware or teardown could be matched conclusively to that board.

Visible features included a lithium battery, Micro-USB charging, a laser warning, a crystal and possible TX/RX test points. These do not establish that UART flashing is possible.

The remote turned out to support BLE HID input that the TV could already receive. The final task was fixing the TV's button configuration, rather than modifying the remote.

## ESP32 was only an exploratory tool

The test board was an ESP32-S3 with 16MB flash and 8MB PSRAM. Scanning found `tKeybd`; signal changes as the remote moved closer and farther away supported identification. It advertised HID `0x1812` and Battery `0x180F` services.

ESP32 connection attempts timed out and no usable bridge was completed. A Mac later connected successfully, followed by the TV. **The ESP32 is not part of the final control path.**

## Inspecting buttons on macOS

The keyboard identification assistant appeared during connection, but configuring a full keyboard layout was unnecessary. IOHIDManager reported BLE HID, VID `0x248A`, PID `0x8266`, and keyboard, mouse and consumer-control reports.

These are firmware-reported IDs, not proof of the chip model.

[hid_watch.c](../tools/hid_watch.c) matches only `tKeybd` and those IDs, without exclusive access:

```sh
clang tools/hid_watch.c -framework IOKit -framework CoreFoundation -o /tmp/darling-hid-watch
/tmp/darling-hid-watch
```

Grant Input Monitoring permission if requested. Buttons also reach the foreground app: OK is Keypad Enter and can send a chat message, so move focus to the desktop before testing.

Early tests confused the left target-symbol buttons with the right volume buttons. After checking physical positions, the left pair was identified as F8/F9 and the right pair as standard volume controls. [Full data →](keymap.json)

## The TV's missing mappings

Pairing created Keyboard, Consumer Control and Mouse input nodes. Node numbers can change after reconnection; do not permanently assume `event4` is the keyboard.

`Vendor_248a_Product_8266.idc` points to the Google reference remote's `Vendor_0957_Product_0001.kl`. Its comment says early reference hardware reported these IDs due to a memory error. This explains the system's configuration choice, but does not identify the DARLING as that hardware.

Directions, Home and volume worked. The layout omitted `KEY_KPENTER` (96), `KEY_ESC` (1) and `KEY_COMPOSE` (127): input reached the TV without an appropriate Android destination key.

## Temporary forwarding and the final layout

A Mac-side ADB listener first translated OK and Esc into `input keyevent` calls, proving both operations worked. That temporary solution required the computer to remain running.

Android 12 was then confirmed to support APK-provided KCM overlays, and the TV's ADB shell had `SET_KEYBOARD_LAYOUT` permission. After installing a resource-only layout APK and selecting it through a one-shot helper, the Mac bridge was stopped. The user confirmed OK and Back still worked.

The three-line button sends HID Application/Menu (`07/65`), called `KEY_COMPOSE` by Linux. Mapping it to Android MENU opened player options such as episode selection and quality. **It is not Sony Quick Settings.** The user confirmed power worked natively without remapping.

## Unresolved or incompletely verified

- Sony Quick Settings is a separate system feature. `KEYCODE_SETTINGS` did not open the expected panel; directly starting QuickLauncher opened input selection. Neither path was shipped as a feature.
- During the laser-button test, direction events were received before and after it, but no Bluetooth event could be attributed to the laser button. It may only control the local laser; this does not prove it sends no events in every mode.
- Bluetooth disconnected and sometimes failed to reconnect. Logs included connection-establishment failures and GATT/link timeouts, including a disconnect about four seconds after a parameter update. Low-power compatibility merits investigation, but distance and battery condition have not been ruled out.
- Volume Down initially failed without lighting the indicator, then produced normal events. A contact problem is suspected but was not confirmed by opening the remote.
- Holding Back and Home for five seconds did not establish a confirmed pairing procedure. The laser button's possible role in pairing also remains unproven.
- Layout selection remained after Bluetooth reconnection; persistence across a full TV reboot is untested.

The final path is **DARLING → BLE HID → Android input on the TV**. The metal body motivated choosing this remote; the keyboard layout solves its button compatibility problem.
