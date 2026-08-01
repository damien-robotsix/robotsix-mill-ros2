# Run the fast local lint subset; run `just check-all` for the full CI gate (default when `just` is typed with no args)
check: lint-yaml lint-shell lint-spelling lint-markdown lint-docker validate-manifest lint-actions lint-security

# Run the full CI gate (just check + all pre-commit hooks). Slower; use before pushing.
check-all: check
    pre-commit run --all-files

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

# Lint Dockerfile with hadolint
lint-docker:
    hadolint --failure-threshold error .devcontainer/Dockerfile

# Lint all Markdown files with markdownlint
lint-markdown:
    markdownlint --config .markdownlint.json .
