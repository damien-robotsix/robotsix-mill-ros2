# AGENT.md — robotsix-mill-ros2

A ROS2 workspace skeleton repository. It carries **no Python or ROS2
source code** — it is a workspace orchestrator that declares which
downstream repositories to clone and from where.

## Layout

```
.
├── repos.yaml                    # vcs2l manifest: declares repos to clone into src/
├── scripts/update_workspace.sh   # runs `vcs import` + `vcs pull` from repos.yaml
├── src/                          # ephemeral checkout (git-ignored)
├── .robotsix-mill/config.yaml    # robotsix-mill test gate (yamllint + vcs validate)
├── .github/workflows/ci.yaml     # CI: yamllint, shellcheck, vcs validate, actionlint, codespell
├── .robotsix-mill/periodic/      # audit.yaml, health.yaml, survey.yaml (built-in stubs)
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

# Individual CI checks
yamllint --strict .
shellcheck scripts/update_workspace.sh
vcs validate --input repos.yaml
codespell --ignore-words=.codespell-ignore
actionlint -color
```

The robotsix-mill test gate (`.robotsix-mill/config.yaml`) mirrors
this: it runs `yamllint --strict . && vcs validate --input repos.yaml`
inside the sandbox.

## Dependabot configuration

- **All Dependabot package-ecosystem entries** must include a `groups`
  block with a catch-all pattern (`patterns: ["*"]`) and a
  `cooldown.default-days: 7` to collapse multiple updates into a single
  weekly PR with a safety cooldown. New ecosystems (pip, npm, Docker,
  etc.) should follow the same pattern as the existing `github-actions`
  and `pre-commit` entries.

## Conventions for AI agents

- **No source edits in this repo.** This repo only contains the
  manifest, scripts, CI, and docs. Do not add ROS2 packages, Python
  modules, or C++ source here — those belong in downstream
  repositories declared in `repos.yaml`.
- **Add entries, not forks.** To include more ROS2 packages, append
  entries under `repositories:` in `repos.yaml`. Do not fork the
  skeleton unless you need a divergent workspace identity.
- **YAML linting is strict.** All YAML files must pass
  `yamllint --strict` with the repo's `.yamllint` config (no
  `document-start` markers).
- **Shell scripts must pass ShellCheck.** The update script and any
  new shell scripts are linted via `shellcheck`.
- **No network in CI/mill sandbox.** `vcs import` and `vcs pull`
  require network access — they cannot run in CI or the robotsix-mill
  sandbox. The test gate validates only the manifest syntax, not the
  clone operation.
- **Pre-commit must pass.** All commits must pass the hooks in
  `.pre-commit-config.yaml`.
