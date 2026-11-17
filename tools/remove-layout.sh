#!/bin/sh
set -eu
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    printf '%s\n' 'Usage: sh tools/remove-layout.sh ADB_SERIAL [ARTIFACT_DIRECTORY]' >&2
    exit 2
fi
serial="$1"
root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
artifacts="${2:-$root/android-layout/build}"
test -f "$artifacts/layout-control.jar"
adb -s "$serial" push "$artifacts/layout-control.jar" /data/local/tmp/darling-layout-control.jar
adb -s "$serial" shell 'CLASSPATH=/data/local/tmp/darling-layout-control.jar app_process /system/bin LayoutControl remove local.darling.keylayout/local.darling.keylayout.LayoutsReceiver/darling_tv'
adb -s "$serial" uninstall local.darling.keylayout
printf '%s\n' 'DARLING layout removed. If you saved a different original layout ID, reselect that layout separately.'
