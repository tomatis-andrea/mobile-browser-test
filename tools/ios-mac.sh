#!/usr/bin/env bash
# Test Safari sul simulatore iPhone del MAC di Andrea (non su GitHub). Lo lancia la VPS via ssh con scripts/mac-ios.sh:
# le variabili segrete (TEST_KEY, BASE_URL, AGE_RECIPIENT) arrivano da lì e non vengono salvate sul Mac.
# Log su stderr; su stdout esce SOLO l'archivio dei risultati, criptato con age (chiave pubblica AGE_RECIPIENT).
# DRY_RUN=1: controlla strumenti, rete e decifratura del test, poi si ferma senza avviare il simulatore.
set -euo pipefail
exec 3>&1 1>&2   # tutto ciò che stampo va su stderr; fd 3 = stdout vero (solo l'archivio)
: "${TEST_KEY:?}" "${BASE_URL:?}" "${AGE_RECIPIENT:?}"
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.maestro/bin:$HOME/maestro/bin:$PATH"
missing=""
for t in xcrun maestro java age python3 curl; do command -v "$t" > /dev/null || missing="$missing $t"; done
[ -z "$missing" ] || { echo "MANCANO sul Mac:$missing  (brew install age openjdk; Maestro: https://maestro.mobile.dev)"; exit 2; }

WORK=$(mktemp -d); trap 'cd /; rm -rf "$WORK"; [ -n "${UDID:-}" ] && xcrun simctl shutdown "$UDID" 2>/dev/null || true' EXIT
git clone -q --depth 1 https://github.com/tomatis-andrea/mobile-browser-test "$WORK/repo"; cd "$WORK/repo"

OPENSSL=$(command -v /opt/homebrew/opt/openssl@3/bin/openssl || command -v openssl)   # il LibreSSL di sistema può non bastare
NAME=$(head -1 run.txt | tr -cd 'a-zA-Z0-9_-')
DATA=$("$OPENSSL" enc -d -aes-256-cbc -pbkdf2 -iter 200000 -a -pass env:TEST_KEY -in "tests/$NAME.enc")
while IFS='=' read -r key value; do case "$key" in ''|\#*) continue ;; esac; export "$key=$value"; done <<< "$DATA"
echo "test: $NAME ($(echo "$DATA" | grep -c .) variabili)"
code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$BASE_URL/it" || true)
echo "sito raggiungibile dal Mac: HTTP $code"; [ "$code" = 200 ] || { echo "il Mac non raggiunge il sito (Tailscale acceso?)"; exit 3; }
[ "${DRY_RUN:-}" = 1 ] && { echo "DRY_RUN ok"; exit 0; }

UDID=$(xcrun simctl list devices available -j | python3 flows/pick-iphone.py)
xcrun simctl boot "$UDID" 2>/dev/null || true
for _ in $(seq 1 60); do xcrun simctl list devices | grep "$UDID" | grep -q Booted && break; sleep 5; done
open -a Simulator --args -CurrentDeviceUDID "$UDID" 2>/dev/null || true
sleep 15
set +e; export APP_ID=com.apple.mobilesafari; bash flows/ios.sh "$UDID"; status=$?; set -e
echo "esito test: $status"
tar czf - out maestro-ios.log 2>/dev/null | age -r "$AGE_RECIPIENT" >&3
exit "$status"
