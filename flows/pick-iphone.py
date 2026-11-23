"""Dall'elenco JSON di `xcrun simctl list devices available -j` (stdin) stampa l'UDID di un iPhone "normale" col iOS più recente.
Sul Mac di Andrea esiste un runtime a parte (iOS-27-2-iPhone19-4) con il solo "iPhone Duo", dalla barra di Safari diversa:
si scelgono modelli come "iPhone 18 Pro" in QUALSIASI runtime; solo se non ce ne sono si ripiega sul primo iPhone."""
import json
import os
import re
import sys

devices = json.load(sys.stdin)["devices"]


def ios_version(runtime: str) -> list[int]:
    m = re.search(r"iOS-(\d+(?:-\d+)*)", runtime)
    return [int(n) for n in m.group(1).split("-")] if m else [0]


def phones(pattern):
    found = []
    for runtime, devs in devices.items():
        if "iOS" not in runtime:
            continue
        for d in devs:
            if d["name"].startswith("iPhone") and "SE" not in d["name"] and re.fullmatch(pattern, d["name"]):
                # prima il iOS più recente, poi "Pro" (schermo più tipico)
                found.append((ios_version(runtime), "Pro" in d["name"], d["name"], d["udid"], runtime))
    return sorted(found, reverse=True)


# modello voluto (default iPhone 17, scelta di Andrea); cambialo con la variabile IPHONE_MODEL
wanted = os.environ.get("IPHONE_MODEL", "iPhone 17")
choice = phones(re.escape(wanted)) or phones(r"iPhone \d+( Pro)?") or phones(r"iPhone.*")
if not choice:
    sys.exit("nessun iPhone disponibile")
_, _, name, udid, runtime = choice[0]
print(udid)
print(runtime, name, file=sys.stderr)
