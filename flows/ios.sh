#!/usr/bin/env bash
# Test Safari sul simulatore iPhone: bash flows/ios.sh <UDID>   (variabili del test già nell'ambiente)
# Il programma di controllo di Maestro (driver XCTest) sul simulatore appena avviato di GitHub a volte non parte nei
# 2 minuti standard ("iOS driver not ready in time"): timeout più largo e, solo per questo errore, un secondo tentativo.
set -uo pipefail
export MAESTRO_DRIVER_STARTUP_TIMEOUT=300000   # millisecondi
export MAESTRO_CLI_NO_ANALYTICS=1
for attempt in 1 2; do
  # Maestro su iOS a volte si pianta senza errore: ogni tentativo ha 6 minuti, poi viene fermato (macOS non ha `timeout`)
  maestro --device "$1" test --test-output-dir out/ios-safari \
    -e APP_ID=com.apple.mobilesafari \
    -e BASE_URL="$BASE_URL" -e PIN="$PIN" -e STAGE_PATH="$STAGE_PATH" -e STAGE_TITLE="$STAGE_TITLE" \
    "flows/$FLOW.yaml" > maestro-ios.log 2>&1 &
  pid=$!
  ( sleep 360; kill "$pid" 2>/dev/null ) &
  watchdog=$!
  wait "$pid"; status=$?
  kill "$watchdog" 2>/dev/null
  cat maestro-ios.log
  [ "$status" -eq 0 ] && exit 0
  # solo i blocchi del programma di controllo si riprovano; un test che fallisce davvero (es. un pulsante assente) no
  if [ "$status" -ne 143 ] && ! grep -q "driver not ready in time" maestro-ios.log; then exit "$status"; fi
  echo "::warning::Maestro iOS bloccato o driver non partito (tentativo $attempt), riprovo"
  pkill -f xctest 2>/dev/null; pkill -f maestro 2>/dev/null; sleep 5
done
exit 1
