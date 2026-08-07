#!/usr/bin/env bash
# Run from: frontend/
# Always cold-boots Pixel_8, then runs Flutter.
set -euo pipefail

export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"
export ANDROID_HOME="${ANDROID_HOME:-/opt/homebrew/share/android-commandlinetools}"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$HOME/development/flutter/bin:$PATH"

cd "$(dirname "$0")"

# Clear stuck Gradle locks from other terminals
pkill -9 -f 'GradleWrapperMain' 2>/dev/null || true
rm -f android/.gradle/noVersion/buildLogic.lock 2>/dev/null || true

adb start-server >/dev/null 2>&1

# Always cold boot Pixel_8
if adb devices | grep -q $'emulator-.*\tdevice'; then
  echo "Closing existing emulator for cold boot..."
  adb emu kill >/dev/null 2>&1 || true
  sleep 2
fi

echo "Cold-booting Pixel_8..."
emulator -avd Pixel_8 -no-snapshot-load -no-boot-anim >/tmp/pixel8.log 2>&1 &

for i in $(seq 1 60); do
  if [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; then
    echo "Emulator ready."
    break
  fi
  printf "  waiting (%s)\n" "$i"
  sleep 5
done

adb devices
flutter run -d emulator-5554
