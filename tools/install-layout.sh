#!/bin/sh
set -eu
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    printf '%s\n' 'Usage: sh tools/install-layout.sh ADB_SERIAL [ARTIFACT_DIRECTORY]' >&2
    exit 2
fi
serial="$1"
root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
artifacts="${2:-$root/android-layout/build}"
test -f "$artifacts/darling-tv-layout.apk"
test -f "$artifacts/layout-control.jar"
adb -s "$serial" push "$artifacts/layout-control.jar" /data/local/tmp/darling-layout-control.jar
printf '%s\n' 'Save the BEFORE layout ID below if it is not null:'
adb -s "$serial" shell 'CLASSPATH=/data/local/tmp/darling-layout-control.jar app_process /system/bin LayoutControl'
adb -s "$serial" install -r "$artifacts/darling-tv-layout.apk"
adb -s "$serial" shell 'CLASSPATH=/data/local/tmp/darling-layout-control.jar app_process /system/bin LayoutControl apply local.darling.keylayout/local.darling.keylayout.LayoutsReceiver/darling_tv'
printf '%s\n' 'Disconnect ADB and test OK, Back and Menu. This script leaves no key-event bridge running.'
