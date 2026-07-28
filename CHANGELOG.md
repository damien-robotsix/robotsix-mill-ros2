# Changelog

All notable changes to robotsix-mill are documented in this file.

The format is adapted from [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.0.0 (unreleased)

### Added

- Restrict stale workflow top-level permissions to `{}`; job-level permissions remain unchanged.
- Add hadolint pre-commit hook for Dockerfile linting, a `lint-docker` just recipe, and fix the first `apt-get install` block in `.devcontainer/Dockerfile` to include `rm -rf /var/lib/apt/lists/*` cleanup.
- Enable `completeness_check` periodic workflow to validate repo manifest completeness (repos.yaml, pre-commit hooks, CI workflows, shell scripts)
- Enable `copy_paste` periodic workflow (jscpd) for YAML/shell copy-paste detection across `.pre-commit-config.yaml`, `.robotsix-mill/config.yaml`, CI workflows, and issue templates.
- Enable the `survey` periodic mill workflow
- Add `changelog_autofill` periodic workflow stub to enable deterministic changelog maintenance.
- Add `check-json` pre-commit hook to validate JSON files (`.devcontainer/devcontainer.json`, `.markdownlint.json`).
- Add `repo_description_sync` periodic workflow to keep forge description in sync with README.
- Add `lint-markdown` recipe to justfile and include it in the `check` dependency list after `lint-spelling`.
- Add markdownlint-cli pre-commit hook with `.markdownlint.json` config for consistent documentation formatting. Hooks into both `pre-commit` (via `igorshubovych/markdownlint-cli` v0.49.0) and `just lint-markdown` / `just check` recipes, and adds a `lint-markdown` matrix entry to the CI lint job.
- Update ARCHITECTURE.md periodic stubs count from three to four, adding the missing `security_posture.yaml` stub.
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

- Update AGENT.md and ARCHITECTURE.md to document all seven periodic workflow stubs (audit, changelog_autofill, completeness_check, copy_paste, health, repo_description_sync, survey)
- Bump yamllint pre-commit hook from v1.37.1 to v1.38.0
- `README.md`: Added License badge (MIT) linking to the OSI license page.

### Fixed

- Fix `ARCHITECTURE.md` periodic stubs description: stubs only declare a `name:` field, not a cron schedule or intent — the mill supplies those.
- Fix `ARCHITECTURE.md` and `AGENT.md` periodic stub docs: remove stale references to `changelog_autofill` and `security_posture`, add `repo_description_sync`, and correct "four" to "three".
- Fix ARCHITECTURE.md periodic stubs count: correct "four" to "five" and add `changelog_autofill.yaml` to the enumeration of `.robotsix-mill/periodic/` workflow stubs.
- Fix pygrep pre-commit hook regex: use `\A` (file-start anchor) instead of `^` (line-start anchor) so the `changelog-first-line` hook actually validates the first line, rather than matching `# Changelog` anywhere in the file.

### Removed

- Remove `security_posture` periodic workflow stub from `.robotsix-mill/periodic/`

## [0.1.0] — YYYY-MM-DD

### Added

- Initial release: workspace skeleton with `repos.yaml`, `scripts/update_workspace.sh`,
  CI lint workflow (yamllint, shellcheck, vcs-validate, actionlint, codespell),
  pre-commit mirror hooks, community docs (README, CONTRIBUTING, SECURITY, ARCHITECTURE),
  and contributor templates (issue forms, PR template).

[0.1.0]: https://github.com/damien-robotsix/robotsix-mill-ros2/releases/tag/v0.1.0
