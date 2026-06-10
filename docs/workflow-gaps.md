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

Each gap entry above doubles as the ready-to-file payload (Title /
Category / Problem / Impact / Evidence / Proposed remediation) should an
operator with board access need to refile or follow up.
