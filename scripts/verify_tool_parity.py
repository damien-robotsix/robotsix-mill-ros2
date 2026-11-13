#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Damien Robotsix
# SPDX-License-Identifier: MIT
"""Verify tool-version parity between .github/workflows/ci.yaml and
.pre-commit-config.yaml, and resolve CI tool versions from the latter.

.pre-commit-config.yaml is the single source of truth for lint/scan tool
versions. CI lint-matrix entries name the tool with a `tool:` key instead of
pinning a `version:`, and the lint job installs the version printed by
`verify_tool_parity.py --resolve <tool>` (the hook `rev:` with the `v` prefix
stripped and, for hadolint, the hook's trailing patch counter removed). A
Dependabot `pre-commit` rev bump therefore needs no matching ci.yaml edit.

Run without arguments, the script is a self-check: every `tool:` entry must
resolve from .pre-commit-config.yaml, and any tool still pinned by an
explicit matrix `version:` must match its hook `rev:`.

The same lint/scan tools are pinned by exact version in two places: the CI
workflow (lint-matrix `version:` values) and the pre-commit hooks (`rev:` tags). These must not drift, otherwise CI and
local pre-commit can disagree on a finding. This script fails the build when
a tool present in both files has differing versions, so a one-off alignment
cannot silently recur.

Tools that only appear in one file (e.g. vcs2l, which is a local hook with
no `rev:`, or zizmor, which CI runs via the fleet-managed reusable
lint-workflows.yml rather than a pinned ci.yaml job) are intentionally not
compared.
"""

import sys

import yaml

# Map a CI lint-matrix entry's human-readable name to a canonical tool key.
CI_NAME_TO_TOOL = {
    "YAML Lint": "yamllint",
    "ShellCheck": "shellcheck",
    "VCS Validate": "vcs2l",
    "Codespell": "codespell",
    "Markdown Lint": "markdownlint",
    "Actionlint": "actionlint",
    "Docker Lint": "hadolint",
}

# Map a pre-commit hook id to a canonical tool key.
HOOK_TO_TOOL = {
    "shellcheck": "shellcheck",
    "hadolint": "hadolint",
    "actionlint-docker": "actionlint",
    "yamllint": "yamllint",
    "codespell": "codespell",
    "markdownlint": "markdownlint",
}


def load_ci_versions(workflow):
    with open(workflow) as f:
        data = yaml.safe_load(f)
    versions = {}
    jobs = data.get("jobs", {})
    # Lint matrix entries carry a name + version.
    lint = jobs.get("lint", {})
    for entry in lint.get("strategy", {}).get("matrix", {}).get("include", []):
        tool = CI_NAME_TO_TOOL.get(entry.get("name", ""))
        if tool and entry.get("version"):
            versions[tool] = str(entry["version"])
    return versions


def load_ci_sourced_tools(workflow):
    """Return the tool keys of lint-matrix entries that take their version
    from .pre-commit-config.yaml (declared with a `tool:` key)."""
    with open(workflow) as f:
        data = yaml.safe_load(f)
    lint = data.get("jobs", {}).get("lint", {})
    tools = []
    for entry in lint.get("strategy", {}).get("matrix", {}).get("include", []):
        if entry.get("tool"):
            tools.append(str(entry["tool"]))
    return tools


def normalize_hadolint(version):
    """Map a shenxianpeng/hadolint-pre-commit hook rev to the upstream
    hadolint binary version it wraps.

    The hook repo tags each release with the hadolint version plus a
    trailing patch counter (e.g. rev v2.15.1.2 wraps hadolint 2.15.1;
    rev v2.14.0.1 wrapped hadolint 2.14.0). CI downloads the upstream
    hadolint binary directly, so strip the hook's trailing counter before
    comparing. Non-hadolint versions are returned unchanged.
    """
    parts = version.split(".")
    if len(parts) > 3:
        return ".".join(parts[:-1])
    return version


def load_pre_commit_versions(config):
    with open(config) as f:
        data = yaml.safe_load(f)
    versions = {}
    for repo in data.get("repos", []):
        rev = str(repo.get("rev", ""))
        if not rev.startswith("v"):
            continue
        version = rev[1:]
        for hook in repo.get("hooks", []):
            tool = HOOK_TO_TOOL.get(hook.get("id", ""))
            if tool:
                versions[tool] = version
    return versions


def resolve_version(tool, versions):
    """Return the version CI should install for *tool*, or None."""
    version = versions.get(tool)
    if version is None:
        return None
    return normalize_hadolint(version) if tool == "hadolint" else version


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    workflow = ".github/workflows/ci.yaml"
    config = ".pre-commit-config.yaml"
    pc = load_pre_commit_versions(config)
    if argv[:1] == ["--resolve"]:
        if len(argv) != 2:
            print("usage: verify_tool_parity.py [--resolve <tool>]", file=sys.stderr)
            return 2
        version = resolve_version(argv[1], pc)
        if version is None:
            print(
                f"UNRESOLVED: {argv[1]}: no pinned hook rev in {config}",
                file=sys.stderr,
            )
            return 1
        print(version)
        return 0
    if argv:
        print("usage: verify_tool_parity.py [--resolve <tool>]", file=sys.stderr)
        return 2
    ci = load_ci_versions(workflow)
    failed = False
    sourced = load_ci_sourced_tools(workflow)
    for tool in sourced:
        version = resolve_version(tool, pc)
        if version is None:
            print(
                f"UNRESOLVED: {tool}: ci.yaml lint matrix sources it from "
                f"{config}, which has no pinned hook rev for it",
                file=sys.stderr,
            )
            failed = True
        else:
            print(f"OK: {tool}={version} (from {config})", file=sys.stderr)
    common = sorted(set(ci) & set(pc))
    for tool in common:
        ci_v = normalize_hadolint(ci[tool]) if tool == "hadolint" else ci[tool]
        pc_v = normalize_hadolint(pc[tool]) if tool == "hadolint" else pc[tool]
        if ci_v != pc_v:
            print(
                f"VERSION DRIFT: {tool}: ci.yaml={ci[tool]} "
                f"vs .pre-commit-config.yaml={pc[tool]}",
                file=sys.stderr,
            )
            failed = True
    if failed:
        print(
            "Tool versions drifted between .github/workflows/ci.yaml and "
            ".pre-commit-config.yaml. Replace the lint-matrix `version:` with "
            "a `tool:` key so the hook rev is the single source of truth, or "
            "add the missing pinned hook.",
            file=sys.stderr,
        )
        return 1
    for tool in common:
        print(f"OK: {tool}={ci[tool]}", file=sys.stderr)
    if not sourced and not common:
        print("No shared tools found to compare; nothing to verify.", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
