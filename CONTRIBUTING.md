# Contributing

Thanks for your interest in improving **robotsix-mill-ros2**. This is a
thin ROS2 workspace skeleton: the workspace sources are not committed
here but declared in the [`vcs2l`](https://github.com/ros-infrastructure/vcs2l)
manifest [`repos.yaml`](repos.yaml) and cloned into the git-ignored
`src/` on demand. Contributions therefore target the repository's own
tooling — `scripts/update_workspace.sh`, `repos.yaml`, CI, and docs —
not the external ROS2 sources (those live in their respective upstream
forks).

## Development environment setup

- [`vcs2l`](https://github.com/ros-infrastructure/vcs2l) provides the
  `vcs` command. Install it with:

  ```sh
  pip install vcs2l
  # or, on Debian/Ubuntu:
  sudo apt install python3-vcs2l
  ```

  Populating `src/` requires network access: a network-isolated
  environment cannot run `vcs import`.

- [`pre-commit`](https://pre-commit.com/) runs the repository's hooks.
  Install it and register the git hook:

  ```sh
  pip install pre-commit
  pre-commit install
  ```

- A POSIX/bash shell is needed to run the scripts under `scripts/`.

See [`README.md`](README.md) for the full workspace-population workflow
(`./scripts/update_workspace.sh`).

## Testing / validating changes locally

CI runs the individual lint/validate commands defined in the
[`justfile`](justfile) (see [`.github/workflows/ci.yaml`](.github/workflows/ci.yaml)).
You can reproduce them locally before pushing:

```sh
pre-commit run --all-files                 # runs the hooks
just check                                 # runs all lint/validate commands
```

The repo's [`.yamllint`](.yamllint) disables the `document-start` rule.

## Workspace management

After updating `repos.yaml`, populate `src/` with:

```sh
just update
```

To remove build artifacts:

```sh
just clean
```

To build all packages in the workspace (requires a ROS2 environment):

```sh
just build
```

## Code style

- **Shell**: scripts must pass ShellCheck (the
  [`.pre-commit-config.yaml`](.pre-commit-config.yaml) file for the
  pinned shellcheck-precommit version). Follow the style already used in
  `scripts/update_workspace.sh`.
- **YAML**: files must pass `yamllint --strict` under the repo's
  `.yamllint` config. Per project convention, YAML files do NOT use
  `---` document-start markers.
- **General**: the `end-of-file-fixer`, `trailing-whitespace`, and
  `check-added-large-files` hooks must pass — files end with a single
  newline and contain no trailing whitespace.

## Pull-request process

1. Branch off `main`.
2. Keep each PR focused on a single, self-contained change.
3. Write clear, descriptive commit messages.
4. For user-facing changes, add a short entry under the appropriate
   section of `[Unreleased]` in [`CHANGELOG.md`](CHANGELOG.md).
5. Ensure CI (the CI jobs listed above) and `pre-commit run --all-files`
   pass before requesting review.

## Developer Certificate of Origin (DCO)

This repository requires all commits to include a `Signed-off-by` trailer
as per the ROS 2 Developer Certificate of Origin (DCO) standard
([ros2.org](https://docs.ros.org/en/rolling/The-ROS2-Project/Contributing/Developer-Guide.html#developer-certificate-of-origin)).

To sign a commit, use `git commit -s` (or `git commit --signoff`).
Existing unsigned commits on a branch can be fixed with:

```sh
git rebase --signoff HEAD~N   # where N is the number of commits to fix
```

CI enforces this check on every pull request via `.github/workflows/dco.yml`.
Trivial changes (typo fixes, docs, chore) and Dependabot and robotsix-mill bot commits are exempted.

## License & copyright

By contributing, you agree that your contributions are licensed under
the repository's MIT License (see [`LICENSE`](LICENSE)),
`Copyright (c) 2026 Damien Robotsix`.

## Security

Do not report security vulnerabilities in public issues or pull
requests. Instead, report them privately via GitHub's "Report a
vulnerability" feature under the Security tab, as described in
[`SECURITY.md`](SECURITY.md).
