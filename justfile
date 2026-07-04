# Run the full lint + validation suite (default when `just` is typed with no args)
check: lint-yaml lint-shell lint-spelling validate-manifest lint-actions lint-security

# Lint all YAML files with yamllint
lint-yaml:
    yamllint --strict .

# Lint scripts/update_workspace.sh with shellcheck
lint-shell:
    shellcheck scripts/update_workspace.sh

# Check spelling across the repo with codespell
lint-spelling:
    codespell --ignore-words=.codespell-ignore

# Validate repos.yaml structure with vcs validate
validate-manifest:
    vcs validate --input repos.yaml

# Lint GitHub Actions workflow files with actionlint
lint-actions:
    actionlint -color

# Run zizmor security analysis on CI workflows
lint-security:
    zizmor --quiet .

# Populate src/ from repos.yaml (requires network and vcs)
update:
    ./scripts/update_workspace.sh

# Remove colcon build artifacts (build, install, log)
clean:
    rm -rf build install log

# Build the workspace with colcon (requires populated src/ and colcon)
build args="":
    colcon build {{args}}
