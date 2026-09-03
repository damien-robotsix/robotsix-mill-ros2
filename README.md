# robotsix-mill-ros2

[![CI](https://github.com/damien-robotsix/robotsix-mill-ros2/actions/workflows/ci.yaml/badge.svg)](https://github.com/damien-robotsix/robotsix-mill-ros2/actions/workflows/ci.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This repo follows the [robotsix stack standards](https://github.com/damien-robotsix/robotsix-standards).

A minimal ROS2 workspace skeleton. The workspace sources are not
committed to this repository — instead they are declared in a
[`vcs2l`](https://github.com/ros-infrastructure/vcs2l) manifest and cloned
into `src/` on demand.

For the design rationale behind this skeleton — why `vcs2l` over
submodules/worktrees/a monorepo, and how to organize and extend the
workspace — see [`ARCHITECTURE.md`](ARCHITECTURE.md).

## Layout

```text
.
├── repos.yaml                 # vcs2l manifest: which repos to clone into src/
├── scripts/update_workspace.sh # clones/updates src/ from repos.yaml
└── src/                       # workspace source root (contents are git-ignored)
```

The contents of `src/` are git-ignored (only the `.gitkeep` placeholder
is tracked) and are managed entirely via `repos.yaml`. The standard
colcon build outputs (`build/`, `install/`, `log/`) are git-ignored too.

## Prerequisites

- [`vcs2l`](https://github.com/ros-infrastructure/vcs2l), providing the
  `vcs` command. Install it with:

  ```sh
  pip install vcs2l
  # or, on Debian/Ubuntu:
  sudo apt install python3-vcs2l
  ```

  If the `vcs` command is missing, `./scripts/update_workspace.sh` will
  attempt to install it automatically (via `pip install --user vcs2l`).
  A network connection is required both for that bootstrap and for the
  subsequent clone/import step, so a network-isolated environment cannot
  populate the workspace even after `vcs2l` is installed.

## Populating / updating the workspace

Add the repositories you want under `repositories:` in `repos.yaml`,
then run:

```sh
./scripts/update_workspace.sh
```

This imports every repo listed in `repos.yaml` into `src/` and pulls
updates for any already-cloned repos, so it is safe to re-run.

## Verify the workspace

Two `just` recipes help you detect workspace drift. Both are **dev-only**
commands that are intentionally excluded from CI and the `just check`
aggregate:

- `just verify-refs` — checks that every `version:` ref declared in
  `repos.yaml` still resolves on its remote (requires network; runs
  `git ls-remote`).
- `just workspace-status` — a **local, no-network** check that runs
  `vcs status src` and diffs the live checkout state (`vcs export --exact`)
  against the committed `repos.yaml` so you can see exactly which repos
  have drifted off their declared refs.

Use `just workspace-status` before running `./scripts/update_workspace.sh`
to preview what will change, and `just verify-refs` to confirm that every
declared ref still exists on the remote before attempting a pull.

## Troubleshooting

### `vcs` command not found (vcs2l installation issues)

`update_workspace.sh` prints `vcs2l not found — install it with: pip
install vcs2l (or: sudo apt install python3-vcs2l)` and exits when it
cannot bootstrap `vcs2l` automatically. Typical causes and fixes:

- **Missing or unusable `pip`** — the script bootstraps with
  `python3 -m pip install --user vcs2l`. Confirm the interpreter and pip
  are usable (`python3 --version`, `python3 -m pip --version`), then
  install manually with `pip install vcs2l` (or
  `sudo apt install python3-vcs2l` on Debian/Ubuntu).
- **`~/.local/bin` not on `PATH`** — a `--user` install places the
  `vcs` binary in `~/.local/bin`, which many shells do not search. After
  installing, run `command -v vcs`; if it is still missing, add
  `~/.local/bin` to `PATH` or install system-wide.
- **No write permission to `~/.local`** — the automatic `--user`
  install fails with a permission error. Use a virtual environment
  (`python3 -m venv`) or a system-wide install instead.

A network-isolated environment cannot bootstrap `vcs2l` at all, and
`vcs import` needs network regardless, so `src/` can only be populated
where network access is available.

### Network errors during `vcs import`

`vcs import` clones every repository declared in `repos.yaml`; `vcs pull`
then updates the ones already cloned into `src/`. Both steps require
network.

- **Network vs. manifest errors** — network failures look like timeouts
  or DNS errors (`fatal: unable to access ... Failed to connect`,
  `Could not resolve host`); manifest errors name a repository or ref
  that does not exist (`Repository not found`, unknown-ref messages).
- **Retry strategy** — the script is idempotent and safe to re-run:
  `./scripts/update_workspace.sh`. Already-cloned repositories are
  pulled, not re-cloned, so retries are cheap.
- **Proxies and firewalls** — git honors the standard `http_proxy` and
  `https_proxy` environment variables; export them when an egress proxy
  is required. If a firewall blocks the protocol used in the `url:`
  field, switch that entry in `repos.yaml` to a reachable protocol.
- `just verify-refs` has the same network prerequisite — it runs
  `git ls-remote` against every declared remote (see below).

### Understanding workspace drift

`just workspace-status` shows two things:

- Raw `vcs status src` output: per-repository branch/ref and dirty-file
  state.
- A diff of `vcs export --exact src` against the committed `repos.yaml`,
  which pinpoints exactly which repositories are checked out on a
  different ref than declared.

Drift happens because `version:` is a floating branch ref: downstream
repositories move on their own when upstream pushes to the branch, and
local edits inside a `src/` checkout also leave it off the declared ref.
Drift simply means the live checkout no longer matches `repos.yaml`. To
sync, re-run `./scripts/update_workspace.sh`; if a repository with local
edits refuses the pull (git-pull semantics), commit or stash those edits
first.

### Branch ref not found

- **Symptoms** — `vcs import` fails for a single repository with a
  ref-not-found message; `just verify-refs` prints
  `ERROR: <path>: ref "<version>" not found on remote <url>` and exits
  non-zero.
- **Cause** — the `version:` value in `repos.yaml` (a branch, tag, or
  commit SHA) does not exist on the remote: a typo, a deleted branch, or
  a ref that was never pushed.
- **Debug** — run `just verify-refs` (requires network) to check every
  declared ref, or `git ls-remote <url> <ref>` for a single repository.
  Correct the `version:` in `repos.yaml`, then re-run
  `./scripts/update_workspace.sh`.

### Recovering a partially updated workspace

If `vcs import` fails midway, `src/` is left partially populated. The
directory is ephemeral — its contents are git-ignored, with only the
empty `.gitkeep` placeholder tracked — so the clean recovery is to
delete it and re-import:

```sh
rm -rf src
./scripts/update_workspace.sh
```

The script recreates `src/`. If `git status` reports `src/.gitkeep` as
deleted, restore the tracked placeholder with
`git checkout -- src/.gitkeep`.

### Which tool should I use?

| Tool | Network | What it checks | When to use |
| --- | --- | --- | --- |
| `just verify-refs` | Required | Every `version:` ref in `repos.yaml` still resolves on its remote (`git ls-remote`) | Before updating, to catch a bad ref early; not usable in isolated/CI environments |
| `just workspace-status` | Not needed | Local drift: `vcs status src` plus the diff of `vcs export --exact src` against `repos.yaml` | Anytime you want to preview what an update will change without touching the network |
| `vcs status src` | Not needed | Raw per-repository output (branch/ref, dirty files) without comparison to `repos.yaml` | A quick low-level look; `just workspace-status` wraps it for drift |
| `./scripts/update_workspace.sh` | Required | Clones and updates `src/` from `repos.yaml` (`vcs import` + `vcs pull`) | The actual populate/update step |

## Development container

This repository includes a [development container](https://containers.dev/) configuration
under `.devcontainer/`. To use it:

1. Install [Docker](https://docs.docker.com/engine/install/) and the
   [Dev Containers extension](vscode:extension/ms-vscode-remote.remote-containers) for VS Code.
2. Open the repository folder in VS Code.
3. When prompted "Reopen in Container", click **Reopen** (or run the
   `Dev Containers: Reopen in Container` command).

The container is configured with ROS 2 Rolling by default. To use a different
ROS 2 distribution, update `ROS_DISTRO` in `.devcontainer/devcontainer.json` before
building (the image must be rebuilt for the change to take effect).

## Pre-commit hooks

This repository uses [pre-commit](https://pre-commit.com/) to catch
simple issues (YAML syntax errors, trailing whitespace, shell script
mistakes, invalid GitHub Actions workflow syntax, accidentally-committed
large files, and common spelling errors) before a commit is created.  To install the hooks:

```sh
pip install pre-commit
pre-commit install
```

After installation, the hooks run automatically on every `git commit`.
You can also run them on-demand against all files:

```sh
pre-commit run --all-files
```
