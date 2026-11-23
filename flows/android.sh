#!/usr/bin/env bash
# Chrome sull'emulatore Android: salta le schermate di benvenuto, poi lancia il test.
set -euo pipefail
adb shell "echo '_ --disable-fre --no-default-browser-check --no-first-run' > /data/local/tmp/chrome-command-line"
adb shell am set-debug-app --persistent com.android.chrome
adb shell am force-stop com.android.chrome
# emulatore lento: senza scheda grafica il Pixel Launcher va in "non risponde" e il popup copre tutto (Chrome non si apre)
adb shell settings put global hide_error_dialogs 1
adb shell settings put global window_animation_scale 0
adb shell settings put global transition_animation_scale 0
adb shell settings put global animator_duration_scale 0
adb shell input keyevent KEYCODE_HOME
sleep 20  # lascia finire l'avvio del launcher
adb shell dumpsys package com.android.chrome | grep -m1 versionName || true
maestro test --test-output-dir out/android-chrome -e APP_ID=com.android.chrome \
  -e BASE_URL="$BASE_URL" -e PIN="$PIN" -e STAGE_PATH="$STAGE_PATH" -e STAGE_TITLE="$STAGE_TITLE" \
  flows/$FLOW.yaml
