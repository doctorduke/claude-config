# GitHub Configuration — BRIEF

## Purpose & Boundary
Provides CI/CD automation, issue/PR templates, and security policies for the umemee-v0 repository. Owns workflows/, ISSUE_TEMPLATE/, and security configurations.

## Interface Contract (Inputs → Outputs)
- **Inputs**: Git push events, PR creation, issue creation, schedule triggers, manual dispatch
- **Outputs**: CI status checks, automated PR reviews, dependency updates, security alerts
- **Web**: GitHub Actions UI shows workflow runs, PR checks display inline
- **Acceptance**:
  - GIVEN code push WHEN tests pass THEN green check mark
  - GIVEN PR opened WHEN BRIEF missing THEN CI blocks merge
- **Anti-Goals**: No deployment automation (handled separately)

## Dependencies & Integration Points
- Upstream: Git hooks, branch protection rules
- Downstream: Merge queue, deployment triggers

## Work State (Planned / Doing / Done)
- **Done**: [CI-01] BRIEF validation workflow

## Spec Snapshot (2025-09-27)
- Features: BRIEF CI checks, PR templates, issue templates
- Tech: GitHub Actions, YAML workflows
- Full spec: workflows/brief-ci.yml

## Decisions & Rationale
- 2025-09-27 — BRIEF validation as required status check (enforces documentation)

## Local Reference Index
- workflows/ → GitHub Actions workflow definitions
- ISSUE_TEMPLATE/ → Issue and PR templates

## Answer Pack (YAML)
kind: answerpack
module: .github/
intent: "GitHub automation and CI/CD workflows"
interfaces:
  inputs: ["push", "pull_request", "workflow_dispatch"]
  outputs: ["status_checks", "PR_comments", "merge_blocking"]