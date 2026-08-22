# EchoStudyExport v1 — Data Contract Specification

## Status
Draft v1 — frozen pending first implementation pass.

## Reference
- ADR-001 (app independence), ADR-003 (data contract & versioning),
  ADR-005 (provenance), ADR-006 (immutability & corrections).

## Purpose

`EchoStudyExport` is the **only** channel through which EchoExpert
data reaches OncoCardio. It is not a mirror of the full EchoExpert
internal domain model (`EchoStudy`) — it is a deliberately narrow,
clinically-scoped subset containing only what OncoCardio actually
consumes for cardio-oncology purposes (baseline assessment, HFA-ICOS
risk input, longitudinal LVEF/GLS monitoring, cardiotoxicity
detection).

Full echo protocol detail (complete valve Doppler grading, chamber
morphology beyond what's listed below, images, strain bull's-eye
maps, etc.) is **out of scope** and remains internal to EchoExpert.
If a future need arises for additional fields, they are added via a
new contract version (ADR-003), not by informally attaching extra
data.

## Design principles

1. **Transport-agnostic.** This document defines the DTO shape, not
   its serialization. Phase 1 transport is a JSON file; the shape
does not change if transport later becomes a local API or FHIR
adapter (ADR-001, ADR-003).
2. **`schema_version` is mandatory** on every export (ADR-003).
3. **Optional fields are genuinely optional — never defaulted.** A
   missing optional field means "not measured / not available", and
   must be represented as absent (not as a normal/zero value) at
every layer that consumes it, including `AlertEngine` and
`RiskEngine`. See "Missing-data semantics" below.
4. **Provenance-friendly.** Every measurement carries enough metadata
   (method, source study id, measured_at) for OncoCardio to build a
   `ProvenanceSummary` (ADR-005) at import time, without needing to
go back to EchoExpert.
5. **No raw images, no waveforms.** This is a structured numeric/
   categorical contract, not a study export in the DICOM sense.

## Field specification

### Envelope

| Field | Type | Required | Notes |
|---|---|---|---|
| `schema_version` | string | yes | e.g. `"1.0"`. See ADR-003 versioning rules. |
| `export_id` | UUID | yes | Unique id of this export event (not the study id). |
| `study_id` | string | yes | EchoExpert's internal study identifier — opaque to OncoCardio, used only for traceability/dedup. |
| `patient_uuid` | UUID | yes | Canonical identity from Patient Registry (ADR-002). EchoExpert must have already resolved the patient against the Registry before exporting — OncoCardio does not attempt to match patients from this DTO. |
| `study_date` | date | yes | Date the echo study was performed. |
| `exported_at` | datetime | yes | When this export was generated. |
| `source_app_version` | string | yes | EchoExpert build/version that produced the export (for provenance, not for compatibility logic — that's `schema_version`'s job). |

### LVEF (mandatory)

| Field | Type | Required | Unit | Notes |
|---|---|---|---|---|
| `lvef_value` | float | yes | % | |
| `lvef_method` | enum | yes | — | `simpson_biplane` \| `3d_echo` \| `visual_estimate` \| `other`. Per clinical principle: prefer Simpson biplane or 3D when available — but the contract records whatever method was actually used; OncoCardio's interpretation layer, not the contract, decides how to weigh a lower-preference method. |
| `lvef_method_detail` | string | no | — | Free-text if `method = other` (e.g. vendor-specific algorithm name). |

### LV volumes (mandatory)

| Field | Type | Required | Unit | Notes |
|---|---|---|---|---|
| `lvedv` | float | yes | ml | LV end-diastolic volume |
| `lvesv` | float | yes | ml | LV end-systolic volume |
| `lvedvi` | float | yes | ml/m² | Indexed to BSA |
| `lvesvi` | float | yes | ml/m² | Indexed to BSA |
| `bsa_value` | float | yes | m² | BSA used for indexing above |
| `bsa_formula` | enum | yes | — | `dubois` \| `mosteller` \| `other` — must be recorded, since indexed values are not comparable across formulas over time if the formula silently changes (ADR-008 applies to this kind of drift too). |

### GLS (optional — recorded and used only if present)

| Field | Type | Required | Unit | Notes |
|---|---|---|---|---|
| `gls_value` | float | **no** | % | Absence means "not assessed", not "normal". |
| `gls_vendor` | string | required if `gls_value` present | — | e.g. `"GE EchoPAC"`, `"TomTec"`, `"Philips QLAB"`. Vendor-specific reference ranges/algorithms mean this value is not directly comparable across vendors — OncoCardio's `LongitudinalAnalysisService` must treat a vendor change within one patient's history as a break in comparability, flagged, not silently trended through. |
| `gls_software_version` | string | no | — | If known. |

> **Missing-data semantics (binding rule, not a suggestion):**
> If `gls_value` is absent, every downstream consumer
> (`AlertEngine`, `RiskEngine`, `LongitudinalAnalysisService`,
> `ReportEngine`) must treat GLS as **unassessed** for this
> timepoint. No Category A/C/D rule may substitute a default,
> assume normalcy, or silently skip the GLS criterion as if it were
> satisfied. Where a rule genuinely depends on GLS and GLS is
> absent, the rule's output must explicitly state "GLS not
> available for this assessment" rather than omit mention of it.

### Structural / additional parameters (optional)

| Field | Type | Required | Unit | Notes |
|---|---|---|---|---|
| `lvmi` | float | no | g/m² | LV mass index |
| `rwt` | float | no | — | Relative wall thickness |
| `lavi` | float | no | ml/m² | LA volume index |
| `diastolic_function_grade` | enum | no | — | `normal` \| `grade_1` \| `grade_2` \| `grade_3` \| `indeterminate` |
| `e_over_e_prime` | float | no | — | Average E/e' if reported |
| `tapse` | float | no | mm | RV systolic function proxy |
| `rv_function_qualitative` | enum | no | — | `normal` \| `mildly_reduced` \| `moderately_reduced` \| `severely_reduced` |
| `significant_valvular_disease` | bool | no | — | Flag only; grading detail stays in EchoExpert. |
| `valvular_disease_note` | string | required if flag true | — | Short free text (e.g. "moderate MR"), not a full report. |
| `pericardial_effusion` | bool | no | — | |

## Compatibility / versioning behavior

Per ADR-003:
- Additive fields → minor version bump, OncoCardio operates in
  `tolerant_minor` mode and records which fields it ignored.
- Breaking changes (rename/retype/removal) → major version bump,
  requires an explicit adapter in OncoCardio; unknown major versions
  are rejected outright, never guessed.
- `compatibility_mode` (`exact | tolerant_minor | adapted_major |
  rejected`) is recorded as part of the import's provenance.

## Explicitly out of scope for v1

- Valve Doppler grading detail beyond the single significance flag.
- Segmental wall motion / strain bull's-eye data.
- Raw images, cine loops, DICOM references.
- Any interpretive text or EchoExpert-generated conclusions — only
  structured measurements cross the boundary; interpretation is
  OncoCardio's responsibility, built from these raw values plus its
  own rule layer.
