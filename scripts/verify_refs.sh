#!/usr/bin/env bash
set -euo pipefail
trap 'echo "verify_refs.sh: error on line ${LINENO} (exit $?): ${BASH_COMMAND}" >&2' ERR

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# This script requires network access — it runs `git ls-remote` against
# every remote declared in repos.yaml. It is NOT suitable for CI or
# sandboxed environments.

# Check for PyYAML (bundled with vcs2l, but verify independently)
python3 -c 'import yaml' 2>/dev/null || {
  echo "PyYAML not found. Install it with: pip install pyyaml" >&2
  exit 1
}

python3 -c '
import sys, yaml, subprocess

with open("repos.yaml") as f:
    manifest = yaml.safe_load(f)

repos = manifest.get("repositories", {})
if not repos:
    print("No repositories declared in repos.yaml", file=sys.stderr)
    sys.exit(0)

failed = False
for path, entry in repos.items():
    url = entry.get("url", "")
    version = entry.get("version", "")
    if not url or not version:
        print(f"WARNING: {path}: missing url or version, skipping", file=sys.stderr)
        continue

    print(f"Checking {path}: ref={version} on {url} ...", file=sys.stderr)
    result = subprocess.run(
        ["git", "ls-remote", url, version],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"ERROR: {path}: git ls-remote failed for {url}", file=sys.stderr)
        if result.stderr.strip():
            print(result.stderr.strip(), file=sys.stderr)
        failed = True
        continue

    if not result.stdout.strip():
        print(f"ERROR: {path}: ref \"{version}\" not found on remote {url}", file=sys.stderr)
        failed = True
    else:
        sha = result.stdout.split()[0]
        print(f"  OK: {path}: {version} -> {sha}", file=sys.stderr)

if failed:
    sys.exit(1)
print("All refs verified.", file=sys.stderr)
'
