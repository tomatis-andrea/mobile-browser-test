#!/usr/bin/env bash
# Test Safari sul simulatore iPhone: bash flows/ios.sh <UDID>   (variabili del test già nell'ambiente)
# Il programma di controllo di Maestro (driver XCTest) sul simulatore appena avviato di GitHub a volte non parte nei
# 2 minuti standard ("iOS driver not ready in time"): timeout più largo e, solo per questo errore, un secondo tentativo.
set -uo pipefail
# diagnostica: ogni 30 s stato del Mac (se si congela, l'ultimo giro mostra cosa lo schiaccia)
( while true; do
    echo "[mac $(date +%H:%M:%S)] $(uptime | sed 's/.*load/load/') | $(vm_stat | awk '/Pages free/{f=$3}/Pages active/{a=$3}END{printf "free %d MB, active %d MB", f*16384/1048576, a*16384/1048576}') | top: $(ps -Ao pcpu,comm -r | sed -n 2,4p | awk '{printf "%s%% %s; ", $1, $2}' | sed 's|/[^ ;]*/||g')"
    sleep 30
  done ) &
export DIAG_PID=$!
trap 'kill $DIAG_PID 2>/dev/null' EXIT
export MAESTRO_DRIVER_STARTUP_TIMEOUT=300000   # millisecondi
export MAESTRO_CLI_NO_ANALYTICS=1
export JAVA_TOOL_OPTIONS="-Xmx640m"   # Maestro (Java) con poca memoria sul Mac di GitHub
for attempt in 1 2; do
  # Maestro su iOS a volte si pianta senza errore: ogni tentativo ha 6 minuti, poi viene fermato (macOS non ha `timeout`)
  maestro --device "$1" test --test-output-dir out/ios-safari \
    -e APP_ID=com.apple.mobilesafari \
    -e BASE_URL="$BASE_URL" -e PIN="$PIN" -e STAGE_PATH="$STAGE_PATH" -e STAGE_TITLE="$STAGE_TITLE" \
    "flows/$FLOW.yaml" > >(tee maestro-ios.log) 2>&1 &
  pid=$!
  ( sleep 360; pkill -9 -P "$pid" 2>/dev/null; kill -9 "$pid" 2>/dev/null; pkill -9 -f 'maestro' 2>/dev/null ) &
  watchdog=$!
  wait "$pid"; status=$?
  kill "$watchdog" 2>/dev/null
  [ "$status" -eq 0 ] && exit 0
  # solo i blocchi del programma di controllo si riprovano; un test che fallisce davvero (es. un pulsante assente) no
  if [ "$status" -ne 143 ] && [ "$status" -ne 137 ] && ! grep -q "driver not ready in time" maestro-ios.log; then exit "$status"; fi
  echo "::warning::Maestro iOS bloccato o driver non partito (tentativo $attempt), riprovo"
  pkill -f xctest 2>/dev/null; pkill -f maestro 2>/dev/null; sleep 5
done
exit 1
