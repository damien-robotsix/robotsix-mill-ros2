# robotsix-mill-ros2

A minimal ROS2 workspace skeleton. The workspace sources are not
committed to this repository — instead they are declared in a
[`vcs2l`](https://github.com/ros-infrastructure/vcs2l) manifest and cloned
into `src/` on demand.

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
mistakes, accidentally-committed large files) before a commit is
created.  To install the hooks:

```sh
pip install pre-commit
pre-commit install
```

After installation, the hooks run automatically on every `git commit`.
You can also run them on-demand against all files:

```sh
pre-commit run --all-files
```
