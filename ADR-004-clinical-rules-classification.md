# ADR-004: Clinical Rules Classification (Data / Code / Hybrid)

## Status
Accepted

## Context

Clinical logic must never be hard-coded as scattered thresholds
(`if lvef < 50: ...`) inside UI or ad-hoc business code, since that
makes updates to guidelines expensive and error-prone, and destroys
traceability. At the same time, forcing genuinely algorithmic,
branching clinical logic into declarative data (e.g. YAML) invents an
informal programming language inside configuration and makes complex
algorithms harder to verify, not easier.

## Decision

Clinical logic is classified into five categories, each with an
explicit representation:

| Category | Examples | Representation |
|---|---|---|
| A. Simple declarative rules | `LVEF < 50 -> alert` | **Data** — condition/threshold/message/guideline ref, executed by a generic rule evaluator |
| B. Mathematical calculations | BSA, QTc formulas, % change | **Code** — pure, named, versioned functions (e.g. `bsa_dubois_v1`), unit-tested directly |
| C. Complex clinical algorithms | Full multi-criteria HFA-ICOS-style decision logic | **Hybrid** — control flow is code (versioned class/function), numeric thresholds/weights used by that code are externalized as versioned parameters |
| D. Risk models | HFA-ICOS, future Anthracycline/HER2/QT/ICI models | **Hybrid**, same pattern as C — implemented as versioned Strategy classes registered by `model_id + version` |
| E. Monitoring protocols | Drug -> schedule template, risk-based modifiers | **Data** — mostly tabular; the engine that composes template + modifiers is stable, reusable code |

Formula: *data represents genuine tables of conditions/thresholds/
schedules; code represents anything with real control flow — but even
code must be identified by a stable version, and its numeric
parameters, where meaningful, are externalized as data for
traceability.*

Any Category C/D implementation must be registered via the Rule/Risk
Model Registry (infrastructure in `medicalcore/rules/`) under an
explicit `model_id` and `version`; a logic change requires a new
version, never an in-place edit of an existing one (see ADR-006 for
the general immutability principle, ADR-008 for versioning of
clinical knowledge).

## Consequences

- Category A/E rules can be updated by editing versioned data without
  a code release.
- Category C/D changes require a code change, but are still fully
  traceable via `model_id + version`, and their outputs carry
  provenance back to a specific version (ADR-005).
- No clinical threshold may appear as a bare literal inside UI code,
  `AlertEngine`, or `MonitoringEngine` control flow — it must originate
  from a registered rule or a named, versioned parameter set.
