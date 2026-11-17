# 安装与开发

[English](setup.en.md) | [返回首页](../README.md)

## 前提

已测试 Sony XR-65X90J 中国版、Android 12、固件 682241。遥控器为直接配对的 DARLING BLE HID，回报 VID `0x248A` / PID `0x8266`。其他设备需要自行验证；该标识不能证明芯片型号。

先在电视“添加配件”中配对遥控器，确认方向、首页或音量能操作。断开其他蓝牙主机的连接，停止测试用开发板的连接尝试。配对组合键仍未确定。

需要电脑安装 Android Platform Tools，并在电视开启、授权 ADB。APK 没有启动界面；安装后还需要选用布局。

## 安装发行版

1. 克隆仓库，获得安装脚本。
2. 从 [Releases](https://github.com/yangyao/sony-bravia-darling-remote/releases) 下载 `darling-tv-layout.apk`、`layout-control.jar` 和 `SHA256SUMS`，放到同一目录。
3. 保持遥控器连接电视，再执行以下命令。将 `TV_IP:5555` 替换为 `adb devices` 中的实际设备标识，将下载目录替换为本机路径。

```sh
git clone https://github.com/yangyao/sony-bravia-darling-remote.git
cd sony-bravia-darling-remote
adb connect TV_IP:5555
adb devices
sh tools/install-layout.sh TV_IP:5555 /path/to/downloaded-files
```

可在下载目录用 `shasum -a 256 -c SHA256SUMS` 校验发行文件。

安装脚本先读取原布局，输出 `BEFORE` 和 `AFTER`。若 `BEFORE` 不是 `null`，请保存原布局 ID，以便还原。随后安装 APK，并调用一次性 helper 选用布局，不会留下按键转发进程。

安装后断开电脑上的 ADB，实测 OK、返回与三横线。方向、首页、音量、电源沿用原生行为。

## 实现

测试电视的设备配置把这组 VID/PID 指向 `Vendor_0957_Product_0001.kl`，遗漏了以下三个 Linux 输入码：

| 输入 | Linux 扫描码 | 补充的 Android 按键 |
| --- | --- | --- |
| Keypad Enter | 96 | `DPAD_CENTER` |
| Esc | 1 | `BACK` |
| Application/Menu（`KEY_COMPOSE`） | 127 | `MENU` |

APK 提供的 KCM：

```text
type OVERLAY
map key 96 DPAD_CENTER
map key 1 BACK
map key 127 MENU
```

Android 12 输入系统可从 APK 加载该覆盖布局，ADB shell 在测试电视上具有选用布局所需的 `SET_KEYBOARD_LAYOUT` 权限。无需写入 `/system`，也无需 root、无障碍服务或后台监听。

布局 ID：

```text
local.darling.keylayout/local.darling.keylayout.LayoutsReceiver/darling_tv
```

## 查看与还原

安装脚本会把 helper 放入电视的 `/data/local/tmp`。遥控器连接时，可查看当前布局：

```sh
adb -s TV_IP:5555 shell 'CLASSPATH=/data/local/tmp/darling-layout-control.jar app_process /system/bin LayoutControl'
```

移除布局选择并卸载 APK：

```sh
sh tools/remove-layout.sh TV_IP:5555 /path/to/downloaded-files
```

本次测试电视原布局是 `null`。若原先有其他自定义布局，按安装时记录的 ID 重新选择：

```sh
adb -s TV_IP:5555 shell 'CLASSPATH=/data/local/tmp/darling-layout-control.jar app_process /system/bin LayoutControl apply ORIGINAL_LAYOUT_ID'
```

将 `ORIGINAL_LAYOUT_ID` 替换为保存的值。卸载不修改系统分区。

## 自行编译

需要 JDK（支持 `javac --release 8`）、Android SDK Platform 34、Build Tools 35.0.1、`zip`：

```sh
export JAVA_HOME=/path/to/jdk
export ANDROID_SDK_ROOT=/path/to/android-sdk
sh android-layout/build.sh
sh tools/install-layout.sh TV_IP:5555
```

产物为 `android-layout/build/darling-tv-layout.apk` 和 `layout-control.jar`。可用 `DARLING_BUILD_TOOLS`、`DARLING_ANDROID_JAR`、`DARLING_JAVA_BIN` 覆盖路径。

首次构建在忽略的 `build/` 中生成本地签名密钥，使用开发密码 `android`。保留密钥用于后续更新，不要用于其他产品；本地密钥和构建产物不进入 Git。若自签名与已安装版本不一致，需要先卸载，再安装并重新选用布局。

## 验证范围

- 停止电脑端临时转发后，OK、返回仍可用；三横线菜单已确认可用。
- 电源原生可用，由使用者确认；未另外记录原始键码。
- 蓝牙断开重连后，布局选择仍在。
- 整机重启后预期保留，但尚未实测。不要卸载布局 APK，否则资源会丢失。
- 三横线是应用内菜单，不是 Sony Quick Settings。
- Android 14 等其他版本的布局 API 和套用条件可能不同；helper 以 Android 12 为目标。

## 参考

- [AOSP Android 12：布局选择与保存](https://android.googlesource.com/platform/frameworks/base/+/android-12.0.0_r1/services/core/java/com/android/server/input/InputManagerService.java)
- [AOSP：KCM 解析实现](https://android.googlesource.com/platform/frameworks/native/+/android-12.0.0_r1/libs/input/KeyCharacterMap.cpp)
- [Sony X90J：Quick Settings](https://www.sony.com/electronics/support/televisions-projectors-lcd-tvs-android-/xr-65x90j/articles/00225435)
