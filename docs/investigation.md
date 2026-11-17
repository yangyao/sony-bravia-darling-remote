# 调查记录

[English](investigation.en.md) | [返回首页](../README.md)

## 从硬件改造转向直接配对

项目最初考虑辨认 DARLING 主控并重刷固件，或用 ESP32 读取按键、桥接到 Sony 电视。照片中 U1 的丝印无法辨认，也没有找到能确定对应同一块板的原厂 SDK、固件或拆解。

可辨认的是锂电池、Micro-USB 充电、激光警告、晶振和疑似 TX/RX 测试点。这些线索不代表一定能通过串口烧录。

后来发现，遥控器原本就支持电视可以接收的 BLE HID。最终需要解决的是电视端的按键配置，而不是改造遥控器。

## ESP32 只用于早期探索

测试板是 ESP32-S3，16MB Flash、8MB PSRAM。扫描器发现 `tKeybd`；随着遥控器移近、移远，信号明显变化，支持它就是目标设备。广播包含 HID `0x1812` 和电池 `0x180F` 服务。

ESP32-S3 的连接尝试超时，没有完成可用桥接。Mac 后来成功连接，电视也成功配对。**ESP32 不参与最终控制路径。**

## 在 Mac 上确认按键

连接时出现过键盘识别向导，不需要把遥控器按完整键盘配置。IOHIDManager 读到 BLE HID、VID `0x248A`、PID `0x8266`，以及键盘、鼠标和多媒体报告。

这些 ID 是固件回报的标识，不能证明实际芯片型号。

[hid_watch.c](../tools/hid_watch.c) 只匹配 `tKeybd` 和这组 VID/PID，以非独占方式监听：

```sh
clang tools/hid_watch.c -framework IOKit -framework CoreFoundation -o /tmp/darling-hid-watch
/tmp/darling-hid-watch
```

系统若要求输入监控权限，需要授予。按键也会发送给当前前台应用；OK 是 Keypad Enter，可能直接发送聊天消息，测试时应把焦点移到桌面。

早期混淆过左侧准星按键与右侧音量按键。重新确认位置后：左侧是 F8/F9，右侧才是标准音量加减。[完整数据 →](keymap.json)

## 电视的映射缺口

配对后，Android 建立 Keyboard、Consumer Control、Mouse 三个输入节点。节点编号可能随重连改变，不能永久假定 `event4` 是键盘。

系统的 `Vendor_248a_Product_8266.idc` 指向 Google 参考遥控器配置 `Vendor_0957_Product_0001.kl`。文件注释提到早期参考遥控器曾因内存错误回报这组 VID/PID；这解释了系统如何选配置，不能反推 DARLING 就是同款硬件。

方向、首页、音量正常，但配置遗漏了 `KEY_KPENTER`（96）、`KEY_ESC`（1）、`KEY_COMPOSE`（127）。输入已到达电视，却没有正确的 Android 目标键。

## 临时转发与最终布局

先在 Mac 上用 ADB 监听，将 OK、Esc 转成 `input keyevent`，确认两键能够正常操作电视。这个临时方案需要电脑一直运行。

随后确认 Android 12 可以从 APK 加载 KCM 覆盖布局，电视的 ADB shell 也有 `SET_KEYBOARD_LAYOUT` 权限。安装纯布局 APK，并用一次性 helper 选用后，停止 Mac 转发，使用者确认 OK、返回仍正常。

三横线发送 HID Application/Menu (`07/65`)，Linux 称为 `KEY_COMPOSE`。映射为 Android MENU 后，可打开播放器的选集、清晰度等菜单。**它不是 Sony Quick Settings。** 电源由使用者确认原生可用，不需要映射。

## 未解决或未完全验证

- Sony Quick Settings 是另一套系统功能。测试 `KEYCODE_SETTINGS` 没有呼出预期快捷设置；直接启动 QuickLauncher 得到的是输入选择。这些入口没有作为正式功能发布。
- 激光键测试时，前后方向键有事件，中间没有可归属于激光键的蓝牙事件。目前可能只控制本机激光，但不能证明所有模式都不会发送事件。
- 蓝牙曾反复断连、重连失败。日志包括连接建立失败、GATT／链路超时，一次在连接参数更新约四秒后断开。低功耗兼容性值得调查，距离、电量等原因尚未排除。
- 音量减曾没有反应且指示灯不亮，后来又发送正常事件，疑似按键接触问题，未拆机确认。
- “返回＋首页五秒”的配对效果未确认；激光键是否参与配对也未证实。
- 蓝牙重连后布局选择仍在；整机重启后的保留情况尚未实测。

最后的控制路径是：**DARLING → BLE HID → 电视 Android 输入系统**。硬件外壳是选择这只遥控器的原因，按键布局是本项目解决的兼容问题。
