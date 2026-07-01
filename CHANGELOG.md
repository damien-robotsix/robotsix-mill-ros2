## 0.0.0 (unreleased)

- Enable the built-in `security_posture` periodic workflow to inspect CI and pre-commit config against OWASP/OpenSSF/SLSA best practices.
- Bump yamllint pre-commit hook from v1.37.1 to v1.38.0
- Add `[group: '…']` attributes to justfile recipes for grouped `just --list` output; move `check` to top as default recipe
# Changelog

All notable changes to robotsix-mill are documented in this file.

The format is adapted from [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `justfile`: Centralized lint/validate commands as `just` recipes (`lint-yaml`, `lint-shell`, `lint-spelling`, `validate-manifest`, `lint-actions`, `check`).
- `.github/workflows/ci.yaml`: Added `workflow_dispatch:` trigger to enable manual CI runs from the Actions UI.
- `CODE_OF_CONDUCT.md`: Contributor Covenant v3.0 code of conduct with reporting instructions.
- `AGENT.md`: AI-agent orientation file describing repo layout, conventions, and commands.
- `AGENT.md`: Documented Dependabot groups-and-cooldown convention for all package ecosystems.
- `.github/workflows/ci.yaml`: Added `zizmor` security audit job for GitHub Actions workflows.
- `.pre-commit-config.yaml`: Added `zizmorcore/zizmor-pre-commit` hook for local security scanning.
### Changed
- `README.md`: Added License badge (MIT) linking to the OSI license page.
### Fixed
### Removed

## [0.1.0] — YYYY-MM-DD

### Added
- Initial release: workspace skeleton with `repos.yaml`, `scripts/update_workspace.sh`,
  CI lint workflow (yamllint, shellcheck, vcs-validate, actionlint, codespell),
  pre-commit mirror hooks, community docs (README, CONTRIBUTING, SECURITY, ARCHITECTURE),
  and contributor templates (issue forms, PR template).

[Unreleased]: https://github.com/damien-robotsix/robotsix-mill-ros2/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/damien-robotsix/robotsix-mill-ros2/releases/tag/v0.1.0
