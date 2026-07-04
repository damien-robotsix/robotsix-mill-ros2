# Changelog

All notable changes to robotsix-mill are documented in this file.

The format is adapted from [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Fix structural indentation of Docker ecosystem entry in `.github/dependabot.yml` — the `docker` entry was incorrectly nested inside the `github-actions` block, producing orphaned fields and duplicate `cooldown` keys. Restructured as a proper independent list item at the `updates:` level.
- Remove `--pid=host` from devcontainer `runArgs` to restore PID namespace isolation and eliminate a container escape vector.
- Add `changelog_autofill` periodic workflow to `.robotsix-mill/periodic/`.

### Added

- Add `lint-markdown` recipe to justfile and include it in the `check` dependency list after `lint-spelling`.
- Add markdownlint-cli pre-commit hook with `.markdownlint.json` config for consistent documentation formatting. Hooks into both `pre-commit` (via `igorshubovych/markdownlint-cli` v0.49.0) and `just lint-markdown` / `just check` recipes.
- Update ARCHITECTURE.md periodic stubs count from three to four, adding the missing `security_posture.yaml` stub.
- Add `step-security/harden-runner` as the first step in all CI jobs (lint, zizmor, pre-commit) with `egress-policy: audit` for network-egress monitoring
- Restore CHANGELOG.md structure: move `# Changelog` to line 1, merge orphaned `## 0.0.0 (unreleased)` entries into `## [Unreleased]`, and add pygrep pre-commit hook to enforce first-line convention.
- Add `#` doc-comment lines to every recipe in `justfile` so `just --list` shows a short description for each target.
- Restructure AGENT.md to follow the new repo-baseline standard: add workspace tier to the opening paragraph and reformat repository conventions as Rule/Rationale sections.
- Add `.devcontainer/` configuration (Dockerfile + devcontainer.json) for one-click ROS2 development environment setup with VS Code Dev Containers.
- Add Dependabot auto-merge caller workflow (`.github/workflows/dependabot-auto-merge.yml`).
- Add link to [robotsix stack standards](https://github.com/damien-robotsix/robotsix-standards) in README.md and AGENT.md.
- Enforce DCO (Developer Certificate of Origin) via `.github/workflows/dco.yml` and `.github/dco.yml`
  - Require `Signed-off-by` trailers on all commits per ROS 2 DCO standard
  - Updated `CONTRIBUTING.md` and `.github/PULL_REQUEST_TEMPLATE.md` to reflect DCO requirements
- Enable the built-in `security_posture` periodic workflow to inspect CI and pre-commit config against OWASP/OpenSSF/SLSA best practices.
- `justfile`: Centralized lint/validate commands as `just` recipes (`lint-yaml`, `lint-shell`, `lint-spelling`, `validate-manifest`, `lint-actions`, `check`).
- `.github/workflows/ci.yaml`: Added `workflow_dispatch:` trigger to enable manual CI runs from the Actions UI.
- `CODE_OF_CONDUCT.md`: Contributor Covenant v3.0 code of conduct with reporting instructions.
- `AGENT.md`: AI-agent orientation file describing repo layout, conventions, and commands.
- `AGENT.md`: Documented Dependabot groups-and-cooldown convention for all package ecosystems.
- `.github/workflows/ci.yaml`: Added `zizmor` security audit job for GitHub Actions workflows.
- `.pre-commit-config.yaml`: Added `zizmorcore/zizmor-pre-commit` hook for local security scanning.

### Changed

- Bump yamllint pre-commit hook from v1.37.1 to v1.38.0
- `README.md`: Added License badge (MIT) linking to the OSI license page.

### Fixed

- Fix ARCHITECTURE.md periodic stubs count: correct "four" to "five" and add `changelog_autofill.yaml` to the enumeration of `.robotsix-mill/periodic/` workflow stubs.
- Fix pygrep pre-commit hook regex: use `\A` (file-start anchor) instead of `^` (line-start anchor) so the `changelog-first-line` hook actually validates the first line, rather than matching `# Changelog` anywhere in the file.

### Removed

## [0.1.0] — YYYY-MM-DD

### Added

- Initial release: workspace skeleton with `repos.yaml`, `scripts/update_workspace.sh`,
  CI lint workflow (yamllint, shellcheck, vcs-validate, actionlint, codespell),
  pre-commit mirror hooks, community docs (README, CONTRIBUTING, SECURITY, ARCHITECTURE),
  and contributor templates (issue forms, PR template).

[Unreleased]: https://github.com/damien-robotsix/robotsix-mill-ros2/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/damien-robotsix/robotsix-mill-ros2/releases/tag/v0.1.0
