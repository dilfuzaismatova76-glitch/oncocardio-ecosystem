# Contributing rules

## Roles

- **Architect / Lead** — owns all architectural and clinical decisions:
  domain model, data contracts, clinical rule classification, versioning
  strategy, provenance structure, patient identity strategy. Final
  arbiter on anything touching clinical correctness or safety.

- **Implementation assistant** (human or AI, e.g. GPT/Claude used for
  code generation) — implements tasks strictly according to the
  specification in `/tasks/*.md` and `/docs/domain/*.md`.
  Does **not** independently:
  - introduce or modify clinical thresholds/formulas,
  - change the structure of RuleVersion / RiskModelVersion / Provenance,
  - change control flow in AlertEngine / MonitoringEngine,
  - make decisions about patient identity matching/merge.

## Process

1. Every change references an ADR (`docs/architecture/ADR-XXX.md`) or a
   Task (`tasks/TASK-XXX.md`). PRs without a reference are not accepted.
2. Changes touching paths listed in `CODEOWNERS` require explicit
   architect review before merge.
3. Any proposed clinical threshold/formula/rule must cite its source
   guideline and version in the PR description and, ideally, in code
   comments / the rule definition itself.
4. Clinical facts (measurements, results) are immutable once recorded.
   Corrections are new events referencing the original record — never
   in-place edits of a recorded clinical value.

## PR checklist

See `.github/pull_request_template.md` — filled in automatically when
opening a PR.
