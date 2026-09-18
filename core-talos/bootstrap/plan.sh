#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
umask 077
mkdir -p private
chmod 700 private
terraform fmt -check
terraform validate
terraform plan -out=private/bootstrap.tfplan
terraform show -json private/bootstrap.tfplan > private/plan.json
python3 - <<'PYTHON'
import json
from pathlib import Path
private = Path("private")
plan = json.loads((private / "plan.json").read_text())
for key, filename in [("machine_configuration", "controlplane.yaml"), ("talosconfig", "talosconfig")]:
    output = plan["planned_values"]["outputs"][key]
    if "value" not in output:
        raise SystemExit("Configuration unknown until apply; inspect the secrets resource changes first.")
    (private / filename).write_text(output["value"])
PYTHON
chmod 600 private/*
talosctl validate --config private/controlplane.yaml --mode metal --strict
