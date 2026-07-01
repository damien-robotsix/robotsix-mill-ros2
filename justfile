[group: 'check']
check: lint-yaml lint-shell lint-spelling validate-manifest lint-actions lint-security

[group: 'lint']
lint-yaml:
    yamllint --strict .

[group: 'lint']
lint-shell:
    shellcheck scripts/update_workspace.sh

[group: 'lint']
lint-spelling:
    codespell --ignore-words=.codespell-ignore

[group: 'validate']
validate-manifest:
    vcs validate --input repos.yaml

[group: 'lint']
lint-actions:
    actionlint -color

[group: 'lint']
lint-security:
    zizmor --quiet .
