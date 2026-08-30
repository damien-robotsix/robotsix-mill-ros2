# AGENT.md — robotsix-mill-ros2

This repo follows the [robotsix stack standards](https://github.com/damien-robotsix/robotsix-standards).

A ROS2 workspace skeleton repository (workspace tier). It carries
**no Python or ROS2 source code** — it is a workspace orchestrator
that declares which downstream repositories to clone and from where.

## Layout

```text
.
├── repos.yaml                    # vcs2l manifest: declares repos to clone into src/
├── scripts/update_workspace.sh   # runs `vcs import` + `vcs pull` from repos.yaml
├── src/                          # ephemeral checkout (git-ignored)
├── .robotsix-mill/config.yaml    # robotsix-mill test gate (yamllint + vcs validate)
├── .github/workflows/ci.yaml     # CI: yamllint, shellcheck, vcs validate, actionlint, zizmor, codespell
├── .robotsix-mill/periodic/      # periodic workflow stubs: agent_check, audit, completeness_check, copy_paste, health, repo_description_sync, survey
├── .pre-commit-config.yaml       # pre-commit hooks
├── ARCHITECTURE.md               # design rationale
├── CONTRIBUTING.md               # contribution guide
├── README.md                     # user-facing overview
├── CHANGELOG.md
└── LICENSE                       # MIT
```

## Key concepts

### `repos.yaml` — the vcs2l manifest

Declares which downstream ROS2 repos to clone. Entries are keyed by
destination path relative to `src/`:

```yaml
repositories:
  ros2/example_interfaces:
    type: git
    url: https://github.com/damien-robotsix/example_interfaces
    version: lyrical
```

The `version` field is a **floating branch ref** (not a pinned commit).
This is intentional — re-running the update script tracks the tip of
the branch.

### `scripts/update_workspace.sh`

Bootstraps `vcs2l` if missing, then runs `vcs import src < repos.yaml`
and `vcs pull src`. The script is idempotent and re-runnable.

### `src/` is ephemeral

The contents of `src/` are git-ignored. Only a `.gitkeep` placeholder
is tracked. `src/` can be deleted and re-created at any time by
re-running the update script. Build outputs (`build/`, `install/`,
`log/`) are also git-ignored.

## Build / test / lint commands

```sh
# Populate/update the workspace
./scripts/update_workspace.sh

# Pre-commit (runs yamllint, shellcheck, end-of-file-fixer, trailing-whitespace, codespell)
pre-commit run --all-files

# Full CI gate (lint + all pre-commit hooks)
just check-all

# Fast local lint subset
just check
```

The robotsix-mill test gate (`.robotsix-mill/config.yaml`) mirrors
this: it runs `yamllint --strict . && vcs validate --input repos.yaml`
inside the sandbox.

## Rule: Dependabot entries must include a groups block

**Rationale:** Collapses multiple updates into a single weekly PR with
a safety cooldown, reducing churn and review overhead.

- All Dependabot `package-ecosystem` entries must include a `groups`
  block with a catch-all pattern (`patterns: ["*"]`) and a
  `cooldown.default-days: 7`. New ecosystems (pip, npm, Docker, etc.)
  should follow the same pattern as the existing `github-actions` and
  `pre-commit` entries.

## Rule: No source edits in this repo

**Rationale:** This repo is a workspace orchestrator; downstream
packages live in their own repositories declared in `repos.yaml`.

Do not add ROS2 packages, Python modules, or C++ source here — those
belong in downstream repositories.

## Rule: Add entries, not forks

**Rationale:** Keeps the workspace identity unified and avoids
divergent skeletons that drift apart.

To include more ROS2 packages, append entries under `repositories:`
in `repos.yaml`. Do not fork the skeleton unless you need a divergent
workspace identity.

## Rule: YAML linting is strict

**Rationale:** The CI and robotsix-mill test gate enforce
`yamllint --strict`; non-conforming YAML breaks the pipeline.

All YAML files must pass `yamllint --strict` with the repo's
`.yamllint` config (no `document-start` markers).

## Rule: Shell scripts must pass ShellCheck

**Rationale:** Pre-commit and CI both run `shellcheck`; violations
block merge.

The update script and any new shell scripts are linted via
`shellcheck`.

## Rule: No network in CI/mill sandbox

**Rationale:** `vcs import` and `vcs pull` require network access
which is unavailable in sandboxed CI and robotsix-mill environments.

The test gate validates only the manifest syntax, not the clone
operation. Do not rely on network-dependent steps in CI.

## Rule: Pre-commit must pass

**Rationale:** All commits must pass the hooks in
`.pre-commit-config.yaml`; failing hooks block CI.

Run `pre-commit run --all-files` before pushing.
