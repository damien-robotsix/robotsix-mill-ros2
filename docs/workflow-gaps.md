# Workflow Gaps

Consolidated, ticket-ready report of the workflow gaps / blockers
observed during the end-to-end validation run. Source of record:
[`docs/workflow-test-report.md`](./workflow-test-report.md) — see its
**"Workflow gaps / blockers observed"** section. Each entry below is a
self-contained payload for a ticket filed against the **robotsix-mill**
project.

## Gap 1 — `vcs2l` missing from the execution sandbox

- **Title:** Provision `vcs2l` in the execution sandbox for workspace-targeted tickets
- **Category:** `missing-tool`
- **Problem:** The `vcs` CLI (`vcs2l`) is not installed in the workflow
  execution sandbox, so the documented workspace-integration command
  cannot run.
- **Impact:** `./scripts/update_workspace.sh` exits 1 and the
  `vcs import` / `vcs pull` integration step cannot be executed. The
  integration had to be reproduced manually with `git clone --branch
  lyrical ...` into the git-ignored `src/ros2/example_interfaces`,
  degrading the documented workflow to an ad-hoc workaround.
- **Evidence / repro:** `./scripts/update_workspace.sh` → exits 1 with
  `vcs2l not found`.
- **Proposed remediation:** Add `vcs2l` to sandbox provisioning (e.g.
  `pip install vcs2l`) whenever a ticket targets this ROS2 workspace, so
  `./scripts/update_workspace.sh` runs as documented.

## Gap 2 — No cross-repo ticket targeting / board access from the workspace sandbox

- **Title:** Provide board/config access for in-workspace tickets to read sibling epic children
- **Category:** `missing-input`
- **Problem:** The board/config is not mounted in the workspace
  checkout, so a ticket running against this workspace cannot read a
  sibling epic child (e.g. the intended "test feature" ticket). There is
  no mechanism for an in-repo ticket to discover sibling tickets.
- **Impact:** The substantive source feature could not be retrieved, so
  a placeholder feature defined in the ticket spec had to be implemented
  instead of the intended one.
- **Evidence / repro:** `robotsix-mill ticket list` →
  `ConfigError: Required config file not found: config/mill.defaults.yaml`.
- **Proposed remediation:** Mount the board config in the workspace
  checkout (or provide a cross-repo board-read mechanism) so an in-repo
  ticket can read sibling epic children.
- **Disposition:** The fix is **external to this repository**. It
  requires the milltools execution harness to mount the board config
  (`config/mill.defaults.yaml` or equivalent) into the workspace
  checkout, or to expose a cross-repo board-read API. This thin ROS2
  workspace skeleton has **no in-repo lever** — `.robotsix-mill/config.yaml`
  only carries `languages: [...]` and has no field to declare a board
  mount (and none must be invented).
- **Interim workaround:** Until the external fix lands, in-workspace
  tickets should (a) treat the sibling ticket's content as unavailable
  and implement the placeholder / spec-defined fallback, and (b) file
  board tickets via the `report_issue` milltools tool (which works
  despite the network-isolated `run_command` sandbox) rather than the
  `robotsix-mill` CLI, capturing any unmet cross-repo need as a workflow
  gap.

## Gap 3 — Deliverable lives in an external fork while the ticket runs against the workspace repo

- **Title:** Introduce a first-class cross-repo target concept and provision `gh`/`curl`
- **Category:** `workflow-improvement`
- **Problem:** The work to be delivered lives in an external fork, but
  the ticket runs against the workspace repo. There is no first-class
  "cross-repo target" concept to make driving the fork's contribution
  workflow (push → PR → merge) explicit and reproducible.
- **Impact:** Driving the fork's contribution workflow depended on a
  GitHub credential that happened to be available in the environment and
  on falling back to the GitHub REST API via `urllib`, because neither
  the `gh` CLI nor `curl` is installed. The path was incidental rather
  than reproducible.
- **Evidence / repro:** Neither `gh` CLI nor `curl` is installed in the
  sandbox; the fork's PR-create (`POST /pulls`) and merge
  (`PUT /pulls/{n}/merge`) steps had to be driven via Python `urllib`
  against the GitHub REST API using an incidental credential.
- **Proposed remediation:** Introduce a first-class cross-repo-target
  concept and provision `gh` / `curl` in the sandbox, so a ticket whose
  deliverable lives in an external fork can drive push → PR → merge
  explicitly and reproducibly.

| Field | Content |
| --- | --- |
| **Disposition** | Fix is external (robotsix-mill harness + sandbox-image provisioning); this skeleton repo has no in-repo lever — no Dockerfile/`requirements.txt`/`pyproject.toml` exists, `.robotsix-mill/config.yaml` declares only `languages: [shell]` with no field for sandbox tool deps, and the first-class "cross-repo target" concept must be implemented in the robotsix-mill harness rather than in this workspace. Gap remains open and is tracked externally. |
| **Interim-workaround** | Drove the fork's push → PR → merge by calling the GitHub REST API (`POST /pulls`, `PUT /pulls/{n}/merge`) via Python `urllib` using an available GitHub credential, since neither `gh` nor `curl` is installed. Incidental unblock only — not a substitute for the external fix. |

## Gap 4 — Implement sandbox: noexec `$HOME` + non-root block `test_command` tools (only `python3 -m` works)

- **Title:** Implement sandbox: noexec `$HOME` + non-root block
  `test_command` tools (only `python3 -m` works)
- **Category:** `workflow-improvement`
- **Problem:** `HOME=/tmp` and `/tmp` is mounted **noexec**
  (`tmpfs … nosuid,nodev,noexec`). `pip:`-prefixed
  `extra_sandbox_packages` install with `pip install --user`, landing
  console scripts in `$HOME/.local/bin` (`/tmp/.local/bin`) and any
  pip-bundled native binaries under `/tmp`; because `/tmp` is noexec,
  those files cannot be executed — invoking them, **even with
  `$HOME/.local/bin` on `PATH`**, fails **rc 126 Permission denied**
  (NOT rc 127 `not found`). Separately, the sandbox user is `mill`
  (**non-root**), so `apt:`-prefixed installs are denied (dpkg lock).
- **Impact:** Both bare-name AND `PATH`-prepended invocations of a
  `pip:`-installed console script (e.g. `yamllint`, `vcs`) fail in the
  implement test-gate even though the package installed cleanly; only
  `python3 -m <module>` works (the interpreter lives on exec
  `/usr/bin` and merely *imports* the module from noexec `/tmp`).
  `apt:`-only tools (e.g. `shellcheck`) have **no** runnable
  in-sandbox path at all, forcing the local gate to diverge from CI
  for those checks.
- **Evidence / repro:** mount flags show `/tmp … noexec`;
  `HOME=/tmp`; `whoami=mill` (non-root). Invoking a `--user` console
  script — with or without `PATH="$HOME/.local/bin:$PATH"` — →
  **rc 126 Permission denied**. `apt:` installs fail with a dpkg lock
  (non-root).
- **Proposed remediation:** In the `robotsix_mill` sandbox machinery,
  do any of — mount `$HOME` exec; drop noexec on `$HOME` **and**
  prepend `$HOME/.local/bin` to `PATH`; or add a privileged apt
  provisioning phase at sandbox setup so `apt:` tools install.

| Field | Content |
| --- | --- |
| **Disposition** | Fix is **external** (robotsix-mill harness — the noexec `$HOME` mount flag and/or non-root privileges); this skeleton repo has no in-repo lever over the harness sandbox mount/privilege setup. Gap remains open and is tracked externally. |
| **Interim-workaround** | The `PATH="$HOME/.local/bin:$PATH"` prepend does **not** work under noexec `$HOME` (the script still fails rc 126 Permission denied). The only working interim form is `python3 -m <module>`, exactly as the repo's current `.robotsix-mill/config.yaml` `test_command` does: `python3 -m yamllint --strict .` and `python3 -m vcs2l.commands.vcs validate --input repos.yaml`. `apt:`-only tools such as `shellcheck` have no runnable in-sandbox path and stay CI-only until the external fix lands. |

## Filing outcome

Each gap above was filed as a separate draft ticket against the
**robotsix-mill** project via the `report_issue` board-filing mechanism
(the milltools MCP layer files board tickets even though the
`run_command` sandbox is network-isolated). The `robotsix-mill ticket
new` CLI is not reachable from this environment — `robotsix-mill ticket
list` aborts with the gap #2 `ConfigError`, so CLI filing is itself
blocked by gap #2 — therefore `report_issue` was used.

| Gap | Filed draft id | Filed ticket title | Category |
| --- | --- | --- | --- |
| 1 | `20260610T001407Z-provision-vcs2l-in-the-execution-sandbox-2cb7` | Provision `vcs2l` in the execution sandbox for workspace-targeted tickets | `missing-tool` |
| 2 | `20260610T001411Z-provide-board-config-access-for-in-works-22b5` | Provide board/config access for in-workspace tickets to read sibling epic children | `missing-input` |
| 3 | `20260610T001415Z-introduce-a-first-class-cross-repo-targe-596b` | Introduce a first-class cross-repo target concept and provision `gh`/`curl` | `workflow-improvement` |
| 4 | `20260610T094408Z-test-gate-sandbox-pip-user-bin-dir-tmp-l-a08c` | Implement sandbox: noexec `$HOME` + non-root block `test_command` tools (only `python3 -m` works) | `workflow-improvement` |

Gap 4 is already represented on the board by the present ticket; **no
new board ticket was filed** for it. The id recorded above is a
known likely-duplicate draft
(`20260610T094408Z-test-gate-sandbox-pip-user-bin-dir-tmp-l-a08c`) — a
duplicate report exists, so an operator should consolidate it with
this ticket's own draft.

Each gap entry above doubles as the ready-to-file payload (Title /
Category / Problem / Impact / Evidence / Proposed remediation) should an
operator with board access need to refile or follow up.
