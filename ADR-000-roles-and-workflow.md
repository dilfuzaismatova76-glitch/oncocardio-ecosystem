# ADR-000: Roles and Workflow

## Status
Accepted

## Context

Development of this ecosystem involves both a human architect/lead and
implementation assistants, including AI coding tools (e.g. GPT-based
tools, Claude). Clinical decision-support software cannot have two
independent authorities over clinical logic — divergent interpretations
of the same guideline, introduced independently by different tools,
create patient-safety risk and are expensive to reconcile later.

## Decision

Two roles are defined, with no overlap in authority:

**Architect / Lead**
- Owns all architectural and clinical decisions: domain model, data
  contracts, clinical rule classification, versioning strategy,
  provenance structure, patient identity strategy.
- Final arbiter on anything touching clinical correctness or safety.
- Required reviewer (via `CODEOWNERS`) for all protected paths.

**Implementation assistant** (human or AI)
- Implements tasks strictly according to the specification in
  `/tasks/*.md` and `/docs/domain/*.md`.
- Does **not** independently:
  - introduce or modify clinical thresholds/formulas,
  - change the structure of `RuleVersion` / `RiskModelVersion` /
    `Provenance`,
  - change control flow in `AlertEngine` / `MonitoringEngine`,
  - make decisions about patient identity matching/merge.
- Is well suited to: boilerplate models from an approved spec, unit
  tests against given acceptance criteria, UI scaffolding from an
  approved wireframe, refactors against an explicit rule, documentation.

## Consequences

- Every PR must reference an ADR or a Task file.
- Protected paths (see `CODEOWNERS`) require explicit architect review
  before merge, enforced by branch protection and/or CI
  (`protected-paths.yml`).
- Task specifications must be narrow and complete enough that an
  implementation assistant has no room to make clinical judgment calls.
