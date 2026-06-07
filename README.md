# robotsix-mill-ros2

A minimal ROS2 workspace skeleton. The workspace sources are not
committed to this repository — instead they are declared in a
[`vcstool`](https://github.com/dirk-thomas/vcstool) manifest and cloned
into `src/` on demand.

## Layout

```
.
├── repos.yaml                 # vcstool manifest: which repos to clone into src/
├── scripts/update_workspace.sh # clones/updates src/ from repos.yaml
└── src/                       # workspace source root (contents are git-ignored)
```

The contents of `src/` are git-ignored (only the `.gitkeep` placeholder
is tracked) and are managed entirely via `repos.yaml`. The standard
colcon build outputs (`build/`, `install/`, `log/`) are git-ignored too.

## Prerequisites

- [`vcstool`](https://github.com/dirk-thomas/vcstool), providing the
  `vcs` command. Install it with:

  ```sh
  pip install vcstool
  # or, on Debian/Ubuntu:
  sudo apt install python3-vcstool
  ```

## Populating / updating the workspace

Add the repositories you want under `repositories:` in `repos.yaml`,
then run:

```sh
./scripts/update_workspace.sh
```

This imports every repo listed in `repos.yaml` into `src/` and pulls
updates for any already-cloned repos, so it is safe to re-run.
