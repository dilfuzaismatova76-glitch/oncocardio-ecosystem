# ADR-005: Two-Level Provenance (Summary / Detailed Trace)

## Status
Accepted

## Context

Every clinical output the system produces (an alert, a risk
assessment, an interpretive sentence in a report) must be explainable:
a physician must be able to ask "why did the system show this?" and
get a concrete answer tracing input -> calculation -> rule (and its
version) -> result, without depending on the current state of mutable
rule tables (which may themselves change over time — see ADR-004,
ADR-008). Recording a full step-by-step execution trace for every
single result, however, risks turning the database into an
ever-growing execution log with little added value for simple cases.

## Decision

Provenance is recorded at two levels:

**Level 1 — `ProvenanceSummary` (always recorded)**
```
ProvenanceSummary
  source_measurement_ids: [...]
  rule_id, rule_version            (or risk_model_id, risk_model_version)
  guideline_version_ref
  engine_version
  result
  generated_at
```
Attached to every clinical result without exception (every
`ClinicalAlert`, every `RiskAssessmentResult`, every generated report
sentence).

**Level 2 — `DetailedExecutionTrace` (optional)**
```
DetailedExecutionTrace
  inputs: [ {parameter, value, unit, source, source_app, measured_at}, ... ]
  calculation_steps: [ {function_id, inputs, output}, ... ]
```
Recorded only where a single rule/version reference is insufficient to
make the result self-explanatory to a physician — primarily for
Category C/D outputs (ADR-004): complex multi-criteria algorithms and
risk models, where "why this result" is not obvious from the rule id
alone. Simple Category A threshold alerts are fully explained by the
summary and do not require Level 2.

Both levels, when recorded, are stored as an **immutable snapshot**
attached to the result at creation time — not solely as foreign keys
into current rule tables, since those tables may later be restructured
or archived. Foreign keys/refs remain useful for UI navigation
("show current state of this rule"), but the authoritative
explanation is the frozen snapshot.

## Consequences

- Every clinical result is explainable from the moment it is created,
  independent of future changes to the rules/knowledge base.
- Storage cost is proportional to actual explainability need, not
  applied uniformly regardless of complexity.
- `ProvenanceSummary` must be implemented before or alongside the
  first version of `AlertEngine` — it is not something to retrofit
  later (retrofitting provenance onto historical results is not
  possible).
