# ADR-008: Clinical Knowledge Versioning & Core Library Versioning

## Status
Accepted

## Context

We must be able to open a report generated years ago and know exactly
which guideline, which rule version, which risk model version, and
which thresholds were used to produce it (see ADR-005 for how this is
attached to individual results). Separately, we must define how the
`MedicalCore` library itself is versioned across independently-updated
applications, and make sure this is not confused with Data Contract
versioning (ADR-003), which governs a different, stricter concern.

## Decision

### Clinical knowledge model

```
Guideline (id, name, publishing_body)
  -> GuidelineVersion (version_label, publication_date, source_document_ref)
       -> ClinicalRule (rule_id, category [A-E, see ADR-004])
            -> RuleVersion (definition | code_ref, effective_from/to)
       -> RiskModel (model_id, name)
            -> RiskModelVersion (parameter_set, algorithm_code_ref, effective_from/to)
```

`RuleVersion` and `RiskModelVersion` are immutable once used in any
real patient calculation. A logic or threshold change always creates
a new version; the previous version is closed via `effective_to`, never
deleted or edited.

Optionally, related versions may be grouped for coordinated updates
into a `ClinicalKnowledgePackage` (e.g. `"2026.1"`), which is a
reference aggregate over existing `GuidelineVersion` / `RuleVersion` /
`RiskModelVersion` records — not a new independent data structure.

### Core library versioning

Because each application statically bundles its own `MedicalCore`
snapshot at build time (ADR-001), `EchoExpert` and `OncoCardio` may run
on different Core versions simultaneously without a runtime conflict —
they never share a process. Core is versioned with ordinary semantic
versioning (`MAJOR.MINOR.PATCH`); updating Core in one application does
not affect the other until that application is rebuilt and
redistributed against the new version.

Any change to a clinical calculation function inside Core is made as a
new, separately named/versioned function (e.g. `bsa_dubois_v1`), never
as an in-place change to an existing function's behavior, to preserve
the meaning of historical `ProvenanceSummary.engine_version` references
(ADR-005).

### Explicit separation from Data Contract versioning

Data Contract versioning (ADR-003) is governed independently and more
strictly, because it affects runtime compatibility between two already
installed, independently updated applications exchanging files at run
time — a concern Core library versioning does not have. The two
version numbers (Core library version, Data Contract schema version)
must never be conflated or derived from one another.

## Consequences

- A report or alert generated at any point in time remains fully
  interpretable years later via its recorded `rule_version` /
  `risk_model_version` references (ADR-005).
- Applications can adopt new Core releases on independent timelines.
- Updating clinical knowledge is a data/versioning operation (new
  `RuleVersion`/`RiskModelVersion`), not a silent behavioral change to
  existing code.
