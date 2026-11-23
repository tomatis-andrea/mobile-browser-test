"""Dall'elenco JSON di `xcrun simctl list devices available -j` (stdin) stampa l'UDID di un iPhone col iOS più recente."""
import json
import re
import sys

devices = json.load(sys.stdin)["devices"]


def ios_version(runtime: str) -> list[int]:
    return [int(n) for n in re.findall(r"\d+", runtime.split("iOS-")[-1])]


for runtime in sorted((r for r in devices if "iOS" in r), key=ios_version, reverse=True):
    phones = [d for d in devices[runtime] if d["name"].startswith("iPhone") and "SE" not in d["name"]]
    if phones:
        print(phones[0]["udid"])
        print(runtime, phones[0]["name"], file=sys.stderr)
        break
else:
    sys.exit("nessun iPhone disponibile")
