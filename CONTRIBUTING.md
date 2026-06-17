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

CI runs five jobs (see [`.github/workflows/ci.yaml`](.github/workflows/ci.yaml)).
You can reproduce them locally before pushing:

```sh
pre-commit run --all-files                 # runs the hooks below
shellcheck scripts/update_workspace.sh     # shell-script linting (also a pre-commit hook)
yamllint --strict .                        # YAML linting (honors .yamllint)
vcs validate --input repos.yaml            # validates the workspace manifest
codespell --ignore-words=.codespell-ignore # spell-check source files (also a pre-commit hook)
actionlint -color                          # validate GitHub Actions workflows
```

The repo's [`.yamllint`](.yamllint) disables the `document-start` rule.

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
4. Ensure CI (the CI jobs listed above) and `pre-commit run --all-files`
   pass before requesting review.

Sign-off (DCO `Signed-off-by`) is **not** required for this repository.

## License & copyright

By contributing, you agree that your contributions are licensed under
the repository's MIT License (see [`LICENSE`](LICENSE)),
`Copyright (c) 2026 Damien Robotsix`.

## Security

Do not report security vulnerabilities in public issues or pull
requests. Instead, report them privately via GitHub's "Report a
vulnerability" feature under the Security tab, as described in
[`SECURITY.md`](SECURITY.md).
