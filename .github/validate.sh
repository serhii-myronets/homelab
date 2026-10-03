#!/usr/bin/env bash
# What CI checks on every push, runnable as is from the repository root:
# every kustomization Flux applies builds, and what it builds matches the
# Kubernetes and CRD schemas; every YAML file under docs/ parses, and every
# Markdown record there carries tags. Needs kustomize, kubeconform, python3
# with PyYAML.
set -uo pipefail

crds='https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'
failed=0

# components/ holds kustomize Components, which build only inside an app.
for dir in $(find core/03-gitops/apps -name kustomization.yaml -exec dirname {} \; | sort); do
  if ! built=$(kustomize build "$dir" 2>&1); then
    echo "::error::kustomize build $dir"; echo "$built"; failed=1; continue
  fi
  # A kind with no published schema - a few CRDs - is skipped, not failed.
  if ! printf '%s\n' "$built" | kubeconform -strict -ignore-missing-schemas \
      -schema-location default -schema-location "$crds" -; then
    echo "::error::schema check $dir"; failed=1
  fi
done

python3 - <<'PY' || failed=1
import pathlib, sys, yaml
bad = 0
for p in sorted(pathlib.Path("docs").rglob("*.yaml")):
    try:
        yaml.safe_load(p.read_text())
    except yaml.YAMLError as e:
        print(f"::error file={p}::does not parse: {e}"); bad = 1
for p in sorted(pathlib.Path("docs").rglob("*.md")):
    text = p.read_text()
    if p.name == "README.md" or p.parent.name == "docs":
        continue
    if not text.startswith("---\n"):
        print(f"::error file={p}::no front matter"); bad = 1; continue
    front = yaml.safe_load(text.split("---\n", 2)[1]) or {}
    if not front.get("tags"):
        print(f"::error file={p}::front matter carries no tags"); bad = 1
sys.exit(bad)
PY

exit $failed
