# Run the fast local lint subset; run `just check-all` for the full CI gate (default when `just` is typed with no args)
check: lint-yaml lint-shell lint-spelling lint-markdown lint-docker validate-manifest lint-actions lint-security

# Run the full CI gate (just check + all pre-commit hooks). Slower; use before pushing.
check-all: check
    pre-commit run --all-files

# Lint all YAML files with yamllint
lint-yaml:
    yamllint --strict .

# Lint shell scripts with shellcheck
lint-shell:
    shellcheck scripts/update_workspace.sh scripts/verify_refs.sh

# Check spelling across the repo with codespell
lint-spelling:
    codespell --ignore-words=.codespell-ignore

# Validate repos.yaml structure with vcs validate
validate-manifest:
    vcs validate --input repos.yaml

# Verify that every version: ref in repos.yaml resolves on its remote (requires network; dev-only)
verify-refs:
    ./scripts/verify_refs.sh

# Show workspace drift: vcs status + diff of vcs export --exact against repos.yaml (local, no network)
workspace-status:
    @echo "=== vcs status ==="
    -vcs status src
    @echo ""
    @echo "=== drift from repos.yaml (vcs export --exact vs committed repos.yaml) ==="
    vcs export --exact src | diff repos.yaml - || true

# Run colcon build (devcontainer only)
build:
    colcon build --symlink-install --cmake-args -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache

# Show ccache statistics (devcontainer only)
ccache-stats:
    ccache --show-stats

# Reset ccache statistics (devcontainer only)
ccache-reset:
    ccache --zero-stats

# Lint GitHub Actions workflow files with actionlint
lint-actions:
    actionlint -color

# Run zizmor security analysis on CI workflows
lint-security:
    zizmor --quiet .

# Lint Dockerfile with hadolint
lint-docker:
    hadolint --failure-threshold error .devcontainer/Dockerfile

# Lint all Markdown files with markdownlint
lint-markdown:
    markdownlint --config .markdownlint.json .
