# TASK-005: ImportedEchoMeasurement Model + Import Mapper Stub

## Reference
- docs/domain/oncocardio-domain-model-v1.md, section 4b
  ("Imported echo measurement")
- docs/domain/echostudy-export-v1.md
- TASK-001 (must be completed first — depends on `EchoStudyExport`
  DTO existing)

## Scope

**Part A — Model.**
In `oncocardio/domain/cardiac_assessment.py`, implement
`ImportedEchoMeasurement` per section 4b of the domain model doc.
Mirror field-for-field: mandatory fields required, optional fields
(`gls_value`, `gls_vendor`, `lvmi`, `rwt`, `lavi`,
`diastolic_function_grade`, `e_over_e_prime`, `tapse`,
`rv_function_qualitative`, `significant_valvular_disease`,
`valvular_disease_note`, `pericardial_effusion`) default to `None`.

Include `compatibility_mode: Literal["exact", "tolerant_minor",
"adapted_major", "rejected"]` as specified.

**Part B — Mapper stub (structural mapping only, no interpretation).**
In `oncocardio/domain/mappers/echo_import_mapper.py`, implement:
```
def map_echo_export_to_imported_measurement(
    export: EchoStudyExport,
    cardiac_assessment_event_id: UUID,
    compatibility_mode: str,
) -> ImportedEchoMeasurement:
```
This is a **pure, 1:1 field copy** from `EchoStudyExport` to
`ImportedEchoMeasurement` (same field names/types on both sides by
design — see the domain doc's note that the mandatory section
"mirrors EchoStudyExport mandatory section"). Do not add any
transformation, unit conversion, rounding, or interpretation logic.

## Out of scope

- Do NOT implement `schema_version` compatibility resolution
  (deciding what `compatibility_mode` should be, handling
  `tolerant_minor` field-dropping, major-version adapters/rejection)
  — that logic is architect-authored per ADR-003 and lives elsewhere;
  this task receives `compatibility_mode` as an already-decided
  input parameter.
- Do NOT implement the "GLS absent → treat as unassessed" propagation
  logic in `AlertEngine`/`RiskEngine`/`LongitudinalAnalysisService` —
  this task only produces the data record; downstream consumption of
  the optional-field semantics is a separate, architect-specified
  task per engine.
- Do NOT add persistence code.

## Acceptance criteria

- [ ] `ImportedEchoMeasurement` field set exactly matches domain doc
      section 4b.
- [ ] Mapper correctly copies every mandatory field.
- [ ] Mapper correctly passes through optional fields as `None` when
      absent on the source `EchoStudyExport`, and with their actual
      value when present — verify explicitly with a test case where
      `gls_value` is `None` on the input and remains `None` on the
      output (not defaulted to any other value).
- [ ] Unit tests in
      `tests/oncocardio/domain/mappers/test_echo_import_mapper.py`
      cover: full-data export, minimal (mandatory-only) export, and
      confirm no field is silently dropped or defaulted incorrectly.
