# 調查紀錄

## 一開始想做什麼

原先打算辨認 DARLING 主控並重刷固件，或把 ESP32 裝入遙控器、橋接到 Sony 電視。照片中 U1 的絲印無法辨認；沒有找到能確定對應同一塊板的原廠 SDK、固件或拆解。

可辨認的是鋰電池、Micro-USB 充電、激光警告、主控附近晶振及疑似 TX/RX 測試點。這些線索不代表一定可從串口燒錄。

## ESP32 只用於探索

測試板實際是 ESP32-S3（16MB Flash、8MB PSRAM）。BLE 掃描器找到 `tKeybd`，透過移近、移遠遙控器時的訊號變化，確認它是目標裝置。它宣告了 HID `0x1812` 和電池 `0x180F` 服務。

ESP32-S3 的直接連線嘗試逾時，並未完成可用橋接。最後沒有依賴 ESP32：Mac 後來成功連上裝置，電視也成功配對。

## Mac 確認輸入協議

Mac 的鍵盤識別精靈曾出現，但不需要把遙控器當成完整鍵盤設定。IOHIDManager 顯示 BLE HID、VID `0x248A`、PID `0x8266`，並讀到鍵盤、滑鼠及多媒體報告描述。

[hid_watch.c](../tools/hid_watch.c) 只匹配名稱 `tKeybd` 及這組 VID/PID，以非獨佔方式監聽事件：

```sh
clang tools/hid_watch.c -framework IOKit -framework CoreFoundation -o /tmp/darling-hid-watch
/tmp/darling-hid-watch
```

系統若要求輸入監控權限，需要自行授予。按鍵也會正常送到目前前景應用；OK 是 Keypad Enter，可能直接送出聊天訊息，測試時宜把焦點移到桌面。

早期曾混淆左側準星按鍵和右側音量按鍵。使用者重新確認實體位置後，得到目前 [keymap.json](keymap.json) 的對照。不要把 F8/F9 誤認為音量鍵。

## 電視的映射缺口

配對成功後，Android 建立 Keyboard、Consumer Control、Mouse 三個輸入節點。節點編號可能隨重新連線改變，不應永久假定 `event4` 是鍵盤。

系統的 `Vendor_248a_Product_8266.idc` 把這個裝置指定到 Google 參考遙控器的 `Vendor_0957_Product_0001.kl`。檔案註解指出，早期參考遙控器曾因記憶體錯誤回報這組 VID/PID。這說明系統為何套用該配置，不能反推 DARLING 就是同款硬件。

方向、首頁與音量正常，但該 KL 缺少 Linux `KEY_KPENTER`（96）、`KEY_ESC`（1）、`KEY_COMPOSE`（127）。原始事件已抵達電視，卻沒有正確的 Android 目的鍵。

## 暫時方案與最後方案

曾在 Mac 透過 ADB 監聽原始事件，將 OK、Esc 轉成 `input keyevent`，驗證硬件、連線與目標功能都正常。這個暫時方案需要電腦保持運行，不適合最後使用。

後來確認 Android 12 可從 APK 取得 KCM overlay，且電視的 ADB shell 擁有 `SET_KEYBOARD_LAYOUT` 權限。於是安裝純佈局 APK，透過一次性 helper 選用它。停止 Mac 轉換程式後，使用者確認 OK、返回仍能使用。

三橫線原始事件為 HID Application/Menu (`07/65`)，Linux 稱為 `KEY_COMPOSE`。補成 Android MENU 後，使用者確認播放器內可開啟選集、清晰度等功能。

## 沒有解決的事

- Sony Quick Settings 與應用內 MENU 不同。測試 `KEYCODE_SETTINGS` 未呼出期待的快捷設定；直接啟動實機上的 QuickLauncher 入口得到的是輸入選擇。因此沒有把這些未驗證入口作為正式功能。
- 激光鍵測試時，前後方向鍵有事件，中間未觀察到可歸屬於激光鍵的藍牙事件；目前看來可能只控制本機激光，仍不能證明所有模式下都沒有藍牙事件。
- 連線不穩時，電視日誌出現建立失敗及 GATT／鏈路逾時。一次連線在參數更新後約四秒斷開，值得調查低功耗相容性，但距離、電量等因素未排除。
- 電源鍵已由使用者確認可直接使用，不需要映射；未另外捕捉原始碼。整機重啟後的佈局保留情況，尚未完成實測。

最後的控制路徑始終是：**DARLING → BLE HID → 電視的 Android 輸入系統**。
