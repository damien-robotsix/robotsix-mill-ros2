#!/usr/bin/env python3
"""Verify tool-version parity between .github/workflows/ci.yaml and
.pre-commit-config.yaml.

The same lint/scan tools are pinned by exact version in two places: the CI
workflow (matrix `version:` values and the zizmor action `with:` block) and
the pre-commit hooks (`rev:` tags). These must not drift, otherwise CI and
local pre-commit can disagree on a finding. This script fails the build when
a tool present in both files has differing versions, so a one-off alignment
cannot silently recur.

Tools that only appear in one file (e.g. vcs2l, which is a local hook with
no `rev:`) are intentionally not compared.
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
    "zizmor": "zizmor",
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
    # The zizmor job pins its version in the action `with:` block.
    zizmor = jobs.get("zizmor", {})
    for step in zizmor.get("steps", []):
        if step.get("uses", "").startswith("zizmorcore/zizmor-action"):
            versions["zizmor"] = str(step["with"]["version"])
    return versions


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


def main():
    workflow = ".github/workflows/ci.yaml"
    config = ".pre-commit-config.yaml"
    ci = load_ci_versions(workflow)
    pc = load_pre_commit_versions(config)
    common = sorted(set(ci) & set(pc))
    if not common:
        print("No shared tools found to compare; nothing to verify.", file=sys.stderr)
        return 0
    failed = False
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
            ".pre-commit-config.yaml. Align them (or bump both in one change).",
            file=sys.stderr,
        )
        return 1
    for tool in common:
        print(f"OK: {tool}={ci[tool]}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
