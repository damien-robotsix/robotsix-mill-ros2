#!/usr/bin/env bash
set -euo pipefail
trap 'rc=$?; echo "update_workspace.sh: error on line ${LINENO} (exit ${rc}): ${BASH_COMMAND}" >&2' ERR

# Resolve the repository root from this script's own location so the
# script works regardless of the caller's current working directory.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Verify vcs2l is available before doing anything else. If the vcs
# command is missing, try to bootstrap it (mirrors the CI vcs-validate
# job, which runs `pip install vcs2l`) so this script works unattended
# in any network-capable environment.
if ! command -v vcs >/dev/null 2>&1; then
  echo "vcs not found; attempting to install vcs2l..." >&2
  # Guard the install so a failure (e.g. no network) does not abort the
  # script via `set -e` before the friendly error path below runs.
  if ! python3 -m pip install --user vcs2l >&2; then
    echo "Failed to install vcs2l automatically." >&2
  fi
  # Re-check after the install attempt.
  if ! command -v vcs >/dev/null 2>&1; then
    echo "vcs2l not found — install it with: pip install vcs2l (or: sudo apt install python3-vcs2l)" >&2
    echo "Note: a network-isolated environment cannot bootstrap vcs2l or run 'vcs import' (clones need network)." >&2
    exit 1
  fi
fi

# Ensure the workspace source directory exists.
mkdir -p src

# Import the repos declared in repos.yaml into src/, then pull updates
# for any already-cloned repos so this script is re-runnable.
vcs import src < repos.yaml
vcs pull src

echo "Workspace updated from repos.yaml into ${REPO_ROOT}/src"
