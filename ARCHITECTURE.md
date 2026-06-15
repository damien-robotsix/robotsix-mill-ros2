# Architecture

This document explains the *design* of **robotsix-mill-ros2** — why
the workspace is structured the way it is, and the patterns for
extending it. It is deliberately a rationale-and-patterns document,
not a how-to: for the step-by-step setup and contribution mechanics
see [`README.md`](README.md) and [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Overview: the skeleton model

This repository is a *skeleton* — it carries no ROS2 source code of
its own. Instead, three pieces collaborate to produce a working
workspace:

- [`repos.yaml`](repos.yaml) — the **declaration** layer. A
  [`vcs2l`](https://github.com/ros-infrastructure/vcs2l) manifest
  listing which repositories belong in the workspace and which ref of
  each to check out.
- [`scripts/update_workspace.sh`](scripts/update_workspace.sh) — the
  **realization** layer. It drives `vcs2l` (the `vcs` command) to
  import and pull the declared repositories.
- `src/` — the **checkout**. The directory the sources land in. Its
  contents are git-ignored and ephemeral: only a `.gitkeep`
  placeholder is tracked.

The `vcs` command is the only bridge between the manifest and the
checked-out sources. Nothing in `src/` is authoritative; it can be
deleted and re-created at any time by re-running the update script.
The build outputs colcon produces (`build/`, `install/`, `log/`) are
git-ignored for the same reason — they are derived artifacts, not
source.

This separation is the whole idea: the repository tracks *intent*
(which repos, which refs) while the actual sources live in their own
upstream repositories and are materialized on demand.

## Why vcs2l over the alternatives

The skeleton could instead have embedded the downstream sources
directly. The vcs2l-manifest approach was chosen for the following
reasons. The comparison is meant to be balanced — each alternative
has contexts where it wins.

### vs. git submodules

- **No SHA churn in the skeleton.** Submodules pin an exact commit
  recorded in the superproject's tree, so every downstream update
  produces a commit here just to bump a gitlink. The manifest records
  a ref by name, so the skeleton does not change when downstream
  advances.
- **Declarative and re-runnable.** `update_workspace.sh` imports and
  pulls idempotently; there is no submodule init/sync/update dance and
  no detached-HEAD surprises.
- Submodules do give exact, committed reproducibility — see the note
  on the floating manifest below for why that is intentionally not a
  goal here.

### vs. git worktrees

- Worktrees attach additional working trees to a *single* repository;
  they do not compose *multiple independent* upstream repositories
  into one workspace, which is exactly what a ROS2 `src/` tree needs.
- The manifest expresses a multi-repo set declaratively, where
  worktrees would require manual, per-repository wiring.

### vs. a monorepo

- **No committed sources.** The skeleton stays lightweight: it carries
  only the manifest, scripts, CI, and docs — not the full source of
  every downstream package.
- **Independent ownership.** Each downstream repository keeps its own
  history, issues, and CI. The skeleton does not become a bottleneck
  or a single point of merge contention.
- **Easy to fork.** Because the skeleton is small and declarative,
  forking it to describe a different workspace is cheap (see
  [Fork vs. extend](#fork-vs-extend)).
- A monorepo does offer atomic cross-package commits and a single CI
  surface; the skeleton trades those away for independence and
  lightness.

### The floating manifest is intentional

The `version:` field of each entry is a **floating** ref — a branch
name such as `lyrical` rather than a pinned commit. This is a
deliberate design choice: re-running the update script tracks the tip
of the declared branch, so the workspace follows downstream
development without the skeleton needing edits. The tradeoff is that a
given checkout is not bit-for-bit reproducible from the manifest
alone; that is accepted by design, and pinning/lockfile mechanisms are
intentionally out of scope for this workspace.

## Organizing and extending the workspace

### The manifest schema

Entries live under the top-level `repositories:` key and are **keyed
by destination path**, relative to the directory vcs2l imports into
(here, `src/`). Each entry carries `type`, `url`, and `version`:

```yaml
repositories:
  ros2/example_interfaces:
    type: git
    url: https://github.com/damien-robotsix/example_interfaces
    version: lyrical
```

In this example the key `ros2/example_interfaces` means the repository
is cloned to `src/ros2/example_interfaces`. Adding a repository is a
matter of appending another entry under `repositories:` following the
same shape — there is no separate registration step.

### Destination-path layout

Because the key *is* the destination path, the layout of `src/` is
designed directly in the manifest. Grouping related packages under a
common prefix (for instance, `ros2/<pkg>`) keeps the workspace
organized and makes the intended structure obvious from `repos.yaml`
alone. Choose prefixes that reflect how the packages are grouped
conceptually rather than where they happen to be hosted.

### Best practices for downstream layout

- Keep each downstream repository self-contained: it owns its own
  packages, build configuration, and CI.
- Let a repository contribute one or more ROS2 packages; the
  destination path positions its package(s) within `src/`.
- Keep workspace-wide concerns (the manifest, the update script, CI,
  and docs) in this skeleton, and package-level concerns in the
  downstream repositories — the two layers are intentionally
  separate, as noted in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## CI/CD, testing, and release coordination

The skeleton's CI ([`.github/workflows/ci.yaml`](.github/workflows/ci.yaml),
running on `ubuntu-24.04` for pushes and pull requests to `main` with
`permissions: read-all`) validates the *skeleton itself*, not the
downstream package builds. It runs five jobs:

- `yamllint --strict .` — lint all YAML, including the manifest.
- `shellcheck scripts/update_workspace.sh` — lint the update script.
- `vcs validate --input repos.yaml` — validate that the manifest is
  well-formed.
- `actionlint` — lint the GitHub Actions workflows.
- `codespell --ignore-words=.codespell-ignore` — spell-check source
  files.

The key division of responsibility: this CI confirms the *manifest
and tooling* are correct, while each downstream repository owns the
testing and release of its *own* source. The skeleton never builds or
tests the downstream packages — populating `src/` requires network
access and is out of scope for the skeleton's CI.

The same checks are mirrored for the robotsix-mill tooling in
[`.robotsix-mill/config.yaml`](.robotsix-mill/config.yaml), which
declares `languages: [shell]`, a `test_command` running
`yamllint --strict . && python3 -m vcs2l.commands.vcs validate --input
repos.yaml`, and `extra_sandbox_packages: [pip:yamllint, pip:vcs2l]`.
The `.robotsix-mill/periodic/` directory holds three built-in workflow
stubs — `audit.yaml`, `health.yaml`, and `survey.yaml`.

Release coordination follows from the floating manifest: downstream
repositories cut their own releases on their own branches, and the
workspace tracks them by branch ref. The skeleton does not gate or
orchestrate downstream releases.

## Fork vs. extend

There are two ways to build on this skeleton, and the choice turns on
*workspace identity*:

- **Extend in place** when you want the *same* workspace to include
  more sources. Add entries to `repos.yaml` under `repositories:`;
  no fork is needed. This is the common case — the skeleton is
  designed to grow by accumulating manifest entries.
- **Fork the skeleton** when you want a *divergent* workspace
  identity: a different set of repositories, different CI, or a
  workspace that should evolve independently of this one. Forking is
  cheap precisely because the skeleton is small and declarative — you
  inherit the pattern and replace the manifest contents with your
  own.

If you are only adding repositories you control to the existing
workspace, extend; if you are defining a distinct workspace that
should not share this one's history or CI, fork.
