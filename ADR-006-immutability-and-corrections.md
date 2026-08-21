# ADR-006: Immutability of Clinical Facts + Correction Events

## Status
Accepted

## Context

Longitudinal history (baseline -> cycle 1 -> cycle 2 -> ...) must
never be silently overwritten — this is required both for clinical
safety (trend analysis depends on the original values actually
recorded at each timepoint) and for auditability. However, a blanket
rule of "no UPDATE ever" is impractical: a physician may need to
correct a genuine transcription error (e.g. LVEF entered as 75 instead
of 57), and forcing the erroneous value to remain presented as current
clinical truth is itself unsafe.

## Decision

Distinguish two kinds of change:

- **Clinical fact** (a measurement, a calculated value, a recorded
  result) — immutable once created. Never edited in place.
- **Correction** — a new, separate record referencing the original,
  created through an explicit, attributed workflow.

```
Measurement #101
  value=75, unit=%, status=corrected

Correction #102
  ref_to_original_measurement_id=101
  new_value=57
  reason="transcription error"
  corrected_by=<physician>
  corrected_at=<timestamp>
```

- The original record is never deleted or edited; its `status` field
  transitions (e.g. `active -> corrected` or `-> voided`), and it
  remains permanently visible in history/audit views.
- All downstream computations (`LongitudinalAnalysisService`,
  `RiskEngine`, `AlertEngine`) always resolve to the current
  status-active value in a correction chain — never sum or average
  across superseded duplicates.
- This same pattern applies to demographic corrections in the Patient
  Registry (ADR-002): identity (`patient_uuid`) never changes, but
  demographic fields are corrected through a logged, attributed change,
  not an anonymous in-place update.

## Consequences

- Historical clinical values remain fully auditable — what was
  originally recorded and when it was corrected are both permanently
  visible.
- Clinical calculations are protected from being skewed by erroneous
  legacy values while preserving the audit trail required in a
  regulated medical software context.
- Database schema for clinical tables must be append-only by
  construction (no `UPDATE` statements against recorded clinical
  values), enforced at the repository layer, not left to convention.
