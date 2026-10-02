#!/usr/bin/env bash
set -euo pipefail

# Regression tests for the scenarios documented in README.md (the
# "Troubleshooting" section). Each test builds its own temporary sandbox:
#
#   - a fake repository root (a copy of the script under test plus a minimal
#     repos.yaml), and
#   - either a fake `vcs`/`python3` shim on PATH, or a real local git remote,
#
# so the suite is deterministic, runs offline, and never touches the real
# src/ of this workspace. Intended for CI and local dev (`just test`).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

tests_run=0
tests_failed=0
status=0

ok()   { printf '  ok: %s\n' "$1"; }
info() { printf '\n[%s]\n' "$1"; }

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  tests_failed=$((tests_failed + 1))
}

# run <out_file> <err_file> <cmd...>: execute a command, capture its
# stdout/stderr and exit status into the given files / `${status}`, without
# aborting the suite on a failing command.
run() {
  local out_file err_file
  out_file="$1"
  err_file="$2"
  shift 2
  set +e
  "$@" >"${out_file}" 2>"${err_file}"
  status=$?
  set -e
}

assert_status() {
  local label expected actual err_file
  label="$1"
  expected="$2"
  actual="$3"
  err_file="$4"
  if [ "${actual}" -ne "${expected}" ]; then
    fail "${label}: expected exit ${expected}, got ${actual}; stderr: $(cat "${err_file}")"
  fi
}

assert_out_contains() {
  local label needle file
  label="$1"
  needle="$2"
  file="$3"
  if ! grep -q -F -- "${needle}" "${file}"; then
    fail "${label}: expected stdout to contain [${needle}]; got: $(cat "${file}")"
  fi
}

assert_err_contains() {
  local label needle file
  label="$1"
  needle="$2"
  file="$3"
  if ! grep -q -F -- "${needle}" "${file}"; then
    fail "${label}: expected stderr to contain [${needle}]; got: $(cat "${file}")"
  fi
}

assert_exists() {
  local label path
  label="$1"
  path="$2"
  if [ ! -e "${path}" ]; then
    fail "${label}: expected [${path}] to exist"
  fi
}

run_case() {
  local name before
  name="$1"
  shift
  before="${tests_failed}"
  "$@"
  tests_run=$((tests_run + 1))
  if [ "${tests_failed}" -eq "${before}" ]; then
    ok "${name}"
  else
    printf 'NOT OK: %s\n' "${name}" >&2
  fi
}

# write_fake_workspace <dir>: lay out a fake repository root containing a
# minimal repos.yaml, a copy of update_workspace.sh, and a fake `vcs` shim
# whose behavior is selected via the FAKE_VCS_MODE environment variable.
write_fake_workspace() {
  local d
  d="$1"
  mkdir -p "${d}/scripts" "${d}/bin"
  cp "${REPO_ROOT}/scripts/update_workspace.sh" "${d}/scripts/"
  cat >"${d}/repos.yaml" <<'EOF'
repositories:
  ws/fake:
    type: git
    url: https://example.invalid/ws/fake.git
    version: main
EOF
  cat >"${d}/bin/vcs" <<'EOF'
#!/usr/bin/env bash
# Fake vcs used by the update_workspace.sh tests; behavior selected via mode.
set -euo pipefail
cmd="${1:-}"
case "${FAKE_VCS_MODE:-ok}" in
  ok)
    mkdir -p src/fake_repo
    ;;
  import-fails)
    if [ "${cmd}" = "import" ]; then
      mkdir -p src/partial_repo
      echo "vcs: simulated mid-import failure (partial checkout left in src/)" >&2
      exit 1
    fi
    mkdir -p src/fake_repo
    ;;
  pull-fails)
    mkdir -p src/fake_repo
    if [ "${cmd}" = "pull" ]; then
      echo "vcs: simulated pull refusal (local edits / merge conflict in src/fake_repo)" >&2
      exit 1
    fi
    ;;
  *)
    echo "vcs: unknown FAKE_VCS_MODE=${FAKE_VCS_MODE}" >&2
    exit 1
    ;;
esac
EOF
  chmod +x "${d}/bin/vcs"
}

# Scenario: `vcs` command not found and the automatic bootstrap fails. The
# README documents the exact message and that the script exits.
test_vcs_not_found() {
  local case_dir case_out case_err real_python
  case_dir="${WORK_DIR}/vcs-not-found"
  case_out="${case_dir}/out"
  case_err="${case_dir}/err"
  mkdir -p "${case_dir}/scripts" "${case_dir}/bin" "${case_dir}/home"
  cp "${REPO_ROOT}/scripts/update_workspace.sh" "${case_dir}/scripts/"
  cat >"${case_dir}/repos.yaml" <<'EOF'
repositories: {}
EOF
  # Shim python3 so the automatic `python3 -m pip install --user vcs2l`
  # bootstrap fails, simulating an environment where it cannot work (no
  # network, broken pip, ...). Everything else delegates to the real one.
  real_python="$(command -v python3)"
  cat >"${case_dir}/bin/python3" <<EOF
#!/usr/bin/env bash
if [ "\${1:-}" = "-m" ] && [ "\${2:-}" = "pip" ]; then
  exit 1
fi
exec "${real_python}" "\$@"
EOF
  chmod +x "${case_dir}/bin/python3"
  # Restricted PATH: no vcs anywhere, fake python3 first.
  run "${case_out}" "${case_err}" \
    env -i PATH="${case_dir}/bin:/usr/bin:/bin" HOME="${case_dir}/home" \
    bash "${case_dir}/scripts/update_workspace.sh"
  assert_status "vcs-not-found" 1 "${status}" "${case_err}"
  assert_err_contains "vcs-not-found" \
    "vcs2l not found — install it with: pip install vcs2l" "${case_err}"
}

# Scenario: `vcs import` fails midway, leaving src/ partially populated. The
# README documents `rm -rf src && ./scripts/update_workspace.sh` as the
# recovery; the re-run must recreate src/ and succeed.
test_partial_import_recovery() {
  local case_dir case_out case_err
  case_dir="${WORK_DIR}/partial-import-recovery"
  case_out="${case_dir}/out"
  case_err="${case_dir}/err"
  write_fake_workspace "${case_dir}"
  # First run: import fails mid-way and leaves a partial checkout behind.
  run "${case_out}" "${case_err}" env \
    PATH="${case_dir}/bin:${PATH}" FAKE_VCS_MODE=import-fails \
    bash "${case_dir}/scripts/update_workspace.sh"
  assert_status "partial-import" 1 "${status}" "${case_err}"
  assert_exists "partial-import" "${case_dir}/src/partial_repo"
  # Documented recovery: delete the ephemeral src/ and re-import.
  rm -rf "${case_dir}/src"
  run "${case_out}" "${case_err}" env \
    PATH="${case_dir}/bin:${PATH}" FAKE_VCS_MODE=ok \
    bash "${case_dir}/scripts/update_workspace.sh"
  assert_status "partial-import-recovery" 0 "${status}" "${case_err}"
  assert_exists "partial-import-recovery" "${case_dir}/src/fake_repo"
  assert_out_contains "partial-import-recovery" \
    "Workspace updated from repos.yaml" "${case_out}"
}

# Scenario: `vcs pull` refuses to update a workspace with local edits / a
# merge conflict (git-pull semantics). The README says to commit or stash
# those edits first, then re-run; the re-run must succeed.
test_pull_refusal_recovery() {
  local case_dir case_out case_err
  case_dir="${WORK_DIR}/pull-refusal-recovery"
  case_out="${case_dir}/out"
  case_err="${case_dir}/err"
  write_fake_workspace "${case_dir}"
  run "${case_out}" "${case_err}" env \
    PATH="${case_dir}/bin:${PATH}" FAKE_VCS_MODE=pull-fails \
    bash "${case_dir}/scripts/update_workspace.sh"
  assert_status "pull-refusal" 1 "${status}" "${case_err}"
  assert_err_contains "pull-refusal" "simulated pull refusal" "${case_err}"
  # User resolves local edits, then re-runs the script.
  run "${case_out}" "${case_err}" env \
    PATH="${case_dir}/bin:${PATH}" FAKE_VCS_MODE=ok \
    bash "${case_dir}/scripts/update_workspace.sh"
  assert_status "pull-refusal-recovery" 0 "${status}" "${case_err}"
}

# setup_verify_refs_case <dir>: copy verify_refs.sh into a sandbox and create
# a real local git remote (bare repo with a `main` branch) so the stale-ref
# scenarios can be exercised offline.
setup_verify_refs_case() {
  local d
  d="$1"
  mkdir -p "${d}/scripts"
  cp "${REPO_ROOT}/scripts/verify_refs.sh" "${d}/scripts/"
  git init -q -b main "${d}/work"
  git -C "${d}/work" config user.email "tests@example.com"
  git -C "${d}/work" config user.name "Robotsix tests"
  echo "content" >"${d}/work/file.txt"
  git -C "${d}/work" add file.txt
  git -C "${d}/work" commit -q -m "init"
  git init -q --bare "${d}/remote.git"
  git -C "${d}/work" push -q "${d}/remote.git" main
}

# Scenario: a `version:` ref declared in repos.yaml does not exist on the
# remote. The README documents the exact ERROR line and a non-zero exit.
test_stale_ref_detection() {
  local case_dir case_out case_err
  case_dir="${WORK_DIR}/stale-ref-detection"
  case_out="${case_dir}/out"
  case_err="${case_dir}/err"
  setup_verify_refs_case "${case_dir}"
  cat >"${case_dir}/repos.yaml" <<EOF
repositories:
  ws/good:
    type: git
    url: file://${case_dir}/remote.git
    version: main
  ws/stale:
    type: git
    url: file://${case_dir}/remote.git
    version: no-such-ref
EOF
  run "${case_out}" "${case_err}" bash "${case_dir}/scripts/verify_refs.sh"
  assert_status "stale-ref-detection" 1 "${status}" "${case_err}"
  assert_err_contains "stale-ref-detection" \
    "ERROR: ws/stale: ref \"no-such-ref\" not found on remote file://${case_dir}/remote.git" \
    "${case_err}"
}

# Scenario: every declared ref resolves on its remote; verify_refs.sh must
# exit zero and print its success line.
test_all_refs_pass() {
  local case_dir case_out case_err
  case_dir="${WORK_DIR}/all-refs-pass"
  case_out="${case_dir}/out"
  case_err="${case_dir}/err"
  setup_verify_refs_case "${case_dir}"
  cat >"${case_dir}/repos.yaml" <<EOF
repositories:
  ws/good:
    type: git
    url: file://${case_dir}/remote.git
    version: main
EOF
  run "${case_out}" "${case_err}" bash "${case_dir}/scripts/verify_refs.sh"
  assert_status "all-refs-pass" 0 "${status}" "${case_err}"
  assert_err_contains "all-refs-pass" "All refs verified." "${case_err}"
}

# write_parity_ci <dir>: lay out a fake repo root containing a copy of
# verify_tool_parity.py and a synthetic .github/workflows/ci.yaml carrying
# every lint-matrix tool (plus the zizmor action version). Each test writes
# its own .pre-commit-config.yaml alongside to control the compared set.
write_parity_ci() {
  local d
  d="$1"
  mkdir -p "${d}/scripts" "${d}/.github/workflows"
  cp "${REPO_ROOT}/scripts/verify_tool_parity.py" "${d}/scripts/"
  cat >"${d}/.github/workflows/ci.yaml" <<'EOF'
jobs:
  lint:
    strategy:
      matrix:
        include:
          - name: YAML Lint
            version: "1.38.0"
          - name: ShellCheck
            version: "0.11.0"
          - name: VCS Validate
            version: "1.1.7"
          - name: Codespell
            version: "2.4.3"
          - name: Markdown Lint
            version: "0.49.1"
          - name: Actionlint
            version: "1.7.12"
          - name: Docker Lint
            version: "2.15.1"
  zizmor:
    steps:
      - uses: zizmorcore/zizmor-action@deadbeef  # v0.6.4
        with:
          version: "1.30.0"
EOF
}

# Scenario: load the committed ci.yaml / .pre-commit-config.yaml through the
# script's own loaders and assert the set of tools it would actually compare
# equals the expected shared set. If an upstream CI `name:` or hook `id:` is
# renamed, its mapping lookup returns None, the tool drops out of `common`,
# and this fails loudly instead of letting its drift go silently unchecked.
# Computed from the loaders (not the pass/fail output) so it holds regardless
# of whether versions are currently aligned.
test_parity_all_tools_compared() {
  local case_out case_err
  case_out="${WORK_DIR}/parity-all-out"
  case_err="${WORK_DIR}/parity-all-err"
  run "${case_out}" "${case_err}" \
    python3 -c "import sys; sys.path.insert(0, '${REPO_ROOT}/scripts'); import verify_tool_parity as v; ci = v.load_ci_versions('${REPO_ROOT}/.github/workflows/ci.yaml'); pc = v.load_pre_commit_versions('${REPO_ROOT}/.pre-commit-config.yaml'); common = set(ci) & set(pc); expected = {'zizmor', 'hadolint', 'yamllint', 'shellcheck', 'actionlint', 'codespell', 'markdownlint'}; assert common == expected, 'compared set drifted from expected: %r' % (common ^ expected,); print('parity-set-ok')"
  assert_status "parity-all-tools" 0 "${status}" "${case_err}"
  assert_out_contains "parity-all-tools" "parity-set-ok" "${case_out}"
}

# Scenario: a tool's version differs between ci.yaml and the pre-commit hook.
# The script must detect the drift and exit 1, naming the drifted tool.
test_parity_drift_detected() {
  local case_dir case_out case_err
  case_dir="${WORK_DIR}/parity-drift"
  case_out="${case_dir}/out"
  case_err="${case_dir}/err"
  write_parity_ci "${case_dir}"
  cat >"${case_dir}/.pre-commit-config.yaml" <<'EOF'
repos:
  - repo: https://example.invalid/yamllint
    rev: v1.37.0
    hooks:
      - id: yamllint
  - repo: https://example.invalid/shellcheck
    rev: v0.11.0
    hooks:
      - id: shellcheck
EOF
  run "${case_out}" "${case_err}" \
    bash -c 'cd "$1" && exec python3 scripts/verify_tool_parity.py' _ "${case_dir}"
  assert_status "parity-drift" 1 "${status}" "${case_err}"
  assert_err_contains "parity-drift" "VERSION DRIFT: yamllint" "${case_err}"
}

# Scenario: normalize_hadolint() must strip the shenxianpeng hook's trailing
# patch counter (v2.15.1.2 -> 2.15.1) while leaving ordinary versions alone,
# so a matching hadolint pair is not falsely reported as drift.
test_parity_normalize_hadolint() {
  local case_out case_err
  case_out="${WORK_DIR}/parity-normalize-out"
  case_err="${WORK_DIR}/parity-normalize-err"
  run "${case_out}" "${case_err}" \
    python3 -c "import sys; sys.path.insert(0, '${REPO_ROOT}/scripts'); import verify_tool_parity as v; assert v.normalize_hadolint('2.15.1.2') == '2.15.1', v.normalize_hadolint('2.15.1.2'); assert v.normalize_hadolint('2.14.0.1') == '2.14.0', v.normalize_hadolint('2.14.0.1'); assert v.normalize_hadolint('2.15.1') == '2.15.1', v.normalize_hadolint('2.15.1'); assert v.normalize_hadolint('1.30.0') == '1.30.0', v.normalize_hadolint('1.30.0'); print('normalize-hadolint-ok')"
  assert_status "parity-normalize-hadolint" 0 "${status}" "${case_err}"
  assert_out_contains "parity-normalize-hadolint" "normalize-hadolint-ok" "${case_out}"
}

main() {
  info "update_workspace.sh: vcs missing + uninstallable bootstrap"
  run_case "vcs-not-found" test_vcs_not_found
  info "update_workspace.sh: partial import failure + documented recovery"
  run_case "partial-import-recovery" test_partial_import_recovery
  info "update_workspace.sh: pull refusal (merge conflict) + recovery"
  run_case "pull-refusal-recovery" test_pull_refusal_recovery
  info "verify_refs.sh: stale ref detection"
  run_case "stale-ref-detection" test_stale_ref_detection
  info "verify_refs.sh: all refs pass"
  run_case "all-refs-pass" test_all_refs_pass
  info "verify_tool_parity.py: all expected tools are compared"
  run_case "parity-all-tools-compared" test_parity_all_tools_compared
  info "verify_tool_parity.py: version drift fails loudly"
  run_case "parity-drift-detected" test_parity_drift_detected
  info "verify_tool_parity.py: normalize_hadolint strips hook counter"
  run_case "parity-normalize-hadolint" test_parity_normalize_hadolint

  printf '\n'
  if [ "${tests_failed}" -ne 0 ]; then
    printf 'FAIL: %d of %d tests failed\n' "${tests_failed}" "${tests_run}" >&2
    exit 1
  fi
  printf 'OK: all %d tests passed\n' "${tests_run}"
}

main "$@"
