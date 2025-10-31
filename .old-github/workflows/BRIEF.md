# GitHub Workflows — BRIEF

## Purpose & Boundary
Automated CI/CD pipelines for building, testing, and deploying the umemee-v0 monorepo. Owns all workflow YAML files.

## Interface Contract (Inputs → Outputs)
- **Inputs**: push events, pull_request events, workflow_dispatch, schedule triggers
- **Outputs**: build artifacts, test results, deployment status, PR comments
- **Acceptance**:
  - GIVEN push to trunk WHEN CI runs THEN all checks pass
  - GIVEN PR opened WHEN changes made THEN automated review posted

## Dependencies & Integration Points
- Upstream: Git events, GitHub API
- Downstream: Deployment targets, npm registry

## Work State (Planned / Doing / Done)
- **Done**: BRIEF CI validation, Claude code review

## Spec Snapshot (2025-09-27)
- Features: CI/CD, automated reviews, BRIEF validation
- Files: ci.yml, claude.yml, brief-ci.yml, deploy-web.yml

## Decisions & Rationale
- 2025-09-27 — Claude AI for automated code review

## Local Reference Index
- Individual workflow files document their specific triggers and jobs

## Answer Pack (YAML)
kind: answerpack
module: .github/workflows/
intent: "CI/CD automation for monorepo"