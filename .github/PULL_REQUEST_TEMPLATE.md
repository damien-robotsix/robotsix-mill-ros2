# Summary

<!-- Describe the change and its motivation. -->

Closes #

## Checklist

- [ ] Branched off `main`; single, self-contained change.
- [ ] `pre-commit run --all-files` passes.
- [ ] CI lint commands pass locally:
  - [ ] `shellcheck scripts/update_workspace.sh`
  - [ ] `yamllint --strict .`
  - [ ] `vcs validate --input repos.yaml`
- [ ] Clear, descriptive commit messages.

> Note: DCO `Signed-off-by` sign-off is **not** required for this
> repository.
