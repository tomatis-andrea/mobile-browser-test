#!/usr/bin/env bash
# Prepara un test: tools/nuovo-test.sh <nome> CHIAVE=valore ... (FLOW=tappa, PIN=..., STAGE_PATH=..., STAGE_TITLE=...)
# Scrive tests/<nome>.enc criptato con TEST_KEY (lo stesso valore del segreto TEST_KEY su GitHub, letto qui da
# ~/secrets/mobile-test.env) e mette <nome> in run.txt: il prossimo push lo esegue.
set -euo pipefail
name=$1; shift
[[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "nome non valido: solo lettere, numeri, - e _"; exit 1; }
TEST_KEY=$(sed -n 's/^TEST_KEY=//p' ~/secrets/mobile-test.env)
[ -n "$TEST_KEY" ] || { echo "TEST_KEY mancante in ~/secrets/mobile-test.env"; exit 1; }
printf '%s\n' "$@" | TEST_KEY="$TEST_KEY" openssl enc -aes-256-cbc -pbkdf2 -iter 200000 -salt -a -pass env:TEST_KEY > "tests/$name.enc"
echo "$name" > run.txt
echo "pronto: tests/$name.enc (run.txt = $name)"
