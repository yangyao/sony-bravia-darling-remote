#!/bin/sh
set -eu
cd "$(dirname "$0")"
sdk="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Library/Android/sdk}}"
build_tools="${DARLING_BUILD_TOOLS:-$sdk/build-tools/35.0.1}"
android_jar="${DARLING_ANDROID_JAR:-$sdk/platforms/android-34/android.jar}"
if [ -n "${DARLING_JAVA_BIN:-}" ]; then
    java_bin="$DARLING_JAVA_BIN"
elif [ -n "${JAVA_HOME:-}" ]; then
    java_bin="$JAVA_HOME/bin"
else
    java_bin="$(dirname "$(command -v javac)")"
fi
export JAVA_HOME="$("$java_bin/java" -XshowSettings:properties -version 2>&1 | sed -n 's/^[[:space:]]*java.home = //p')"
mkdir -p build/receiver build/helper build/dex-receiver build/dex-helper
"$java_bin/javac" --release 8 -cp "$android_jar" -d build/receiver src/local/darling/keylayout/LayoutsReceiver.java
"$java_bin/javac" --release 8 -cp "$android_jar" -d build/helper helper/LayoutControl.java
"$build_tools/d8" --min-api 26 --lib "$android_jar" --output build/dex-receiver build/receiver/local/darling/keylayout/LayoutsReceiver.class
"$build_tools/d8" --min-api 26 --lib "$android_jar" --output build/dex-helper build/helper/LayoutControl.class
"$build_tools/aapt2" compile --dir res -o build/resources.zip
"$build_tools/aapt2" link -o build/unsigned.apk --manifest AndroidManifest.xml -I "$android_jar" build/resources.zip
zip -j build/unsigned.apk build/dex-receiver/classes.dex
zip -j build/layout-control.jar build/dex-helper/classes.dex
if [ ! -f build/darling-local.p12 ]; then
    "$java_bin/keytool" -genkeypair -keystore build/darling-local.p12 -storepass android -keypass android -alias darling-local -keyalg RSA -keysize 2048 -validity 3650 -dname 'CN=DARLING Local Layout'
fi
"$build_tools/apksigner" sign --ks build/darling-local.p12 --ks-key-alias darling-local --ks-pass pass:android --key-pass pass:android --out build/darling-tv-layout.apk build/unsigned.apk
"$build_tools/apksigner" verify build/darling-tv-layout.apk
printf '%s\n' 'Built build/darling-tv-layout.apk and build/layout-control.jar (no device changes performed).'
