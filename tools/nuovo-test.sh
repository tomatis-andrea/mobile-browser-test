#!/usr/bin/env bash
# Prepara un test: tools/nuovo-test.sh <nome> CHIAVE=valore ... (es. PIN=..., STAGE_PATH=..., STAGE_TITLE=..., FLOW=tappa)
# Scrive tests/<nome>.enc, criptato con una chiave ricavata da BASE_URL e TS_TARGET (gli stessi valori del segreto
# TEST_CONFIG su GitHub, letti qui da ~/secrets/mobile-test.env), e mette <nome> in run.txt: il prossimo push lo esegue.
set -euo pipefail
name=$1; shift
source ~/secrets/mobile-test.env
key=$(printf '%s|%s' "$BASE_URL" "$TS_TARGET" | sha256sum | cut -d' ' -f1)
printf '%s\n' "$@" | KEY="$key" openssl enc -aes-256-cbc -pbkdf2 -iter 200000 -salt -a -pass env:KEY > "tests/$name.enc"
echo "$name" > run.txt
echo "pronto: tests/$name.enc (run.txt = $name)"
