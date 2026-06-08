#!/usr/bin/env bash
set -euo pipefail

# Resolve the repository root from this script's own location so the
# script works regardless of the caller's current working directory.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Verify vcs2l is available before doing anything else.
if ! command -v vcs >/dev/null 2>&1; then
  echo "vcs2l not found — install it with: pip install vcs2l (or: sudo apt install python3-vcs2l)" >&2
  exit 1
fi

# Ensure the workspace source directory exists.
mkdir -p src

# Import the repos declared in repos.yaml into src/, then pull updates
# for any already-cloned repos so this script is re-runnable.
vcs import src < repos.yaml
vcs pull src

echo "Workspace updated from repos.yaml into ${REPO_ROOT}/src"
