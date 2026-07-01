check: lint-yaml lint-shell lint-spelling validate-manifest lint-actions lint-security

lint-yaml:
    yamllint --strict .

lint-shell:
    shellcheck scripts/update_workspace.sh

lint-spelling:
    codespell --ignore-words=.codespell-ignore

validate-manifest:
    vcs validate --input repos.yaml

lint-actions:
    actionlint -color

lint-security:
    zizmor --quiet .
