#!/usr/bin/env python3
import json,sys
from pathlib import Path
EXPECTED={"passenger_flutter":"com.nexo.astride.passenger","driver_flutter":"com.nexo.astride.driver","partner_flutter":"com.nexo.astride.partner"}
if len(sys.argv)!=3 or sys.argv[1] not in EXPECTED:
    raise SystemExit("usage: validate_firebase_package.py <app> <google-services.json>")
app,path=sys.argv[1],Path(sys.argv[2])
data=json.loads(path.read_text(encoding="utf-8"))
packages={c.get("client_info",{}).get("android_client_info",{}).get("package_name") for c in data.get("client",[])}
expected=EXPECTED[app]
if expected not in packages:
    raise SystemExit(f"Firebase package mismatch for {app}: expected {expected}; found {sorted(x for x in packages if x)}")
print(f"Firebase package verified for {app}: {expected}")
