# robotsix-mill-ros2

[![CI](https://github.com/damien-robotsix/robotsix-mill-ros2/actions/workflows/ci.yaml/badge.svg)](https://github.com/damien-robotsix/robotsix-mill-ros2/actions/workflows/ci.yaml)

A minimal ROS2 workspace skeleton. The workspace sources are not
committed to this repository — instead they are declared in a
[`vcs2l`](https://github.com/ros-infrastructure/vcs2l) manifest and cloned
into `src/` on demand.

For the design rationale behind this skeleton — why `vcs2l` over
submodules/worktrees/a monorepo, and how to organize and extend the
workspace — see [`ARCHITECTURE.md`](ARCHITECTURE.md).

## Layout

```
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
