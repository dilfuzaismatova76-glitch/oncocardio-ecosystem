# TASK-007: SQLite Repository — ImportedEchoMeasurement

## Assigned to
MAI-Code (implementation assistant tier — see
docs/architecture/model-assignment-policy.md).
Non-protected path — architect review required before merge.

## Reference
- docs/architecture/ADR-006-immutability-and-corrections.md
- docs/domain/oncocardio-domain-model-v1.md, section 4b
- TASK-005 (depends on) — `ImportedEchoMeasurement` model in
  `oncocardio/domain/cardiac_assessment.py`
- TASK-004 (depends on) — `Repository[T]` protocol

## Scope

Implement `oncocardio/repository/sqlite/imported_echo_measurement_repository.py`
following the exact same pattern as TASK-006 (append-only `save()`,
`sqlite3` module, parameterized queries, `CREATE TABLE IF NOT EXISTS`,
UUID/datetime/enum serialization conventions).

Additional requirement specific to this entity: **every optional
field (`gls_value`, `gls_vendor`, `lvmi`, `rwt`, `lavi`,
`diastolic_function_grade`, `e_over_e_prime`, `tapse`,
`rv_function_qualitative`, `significant_valvular_disease`,
`valvular_disease_note`, `pericardial_effusion`) must round-trip as
`NULL` in SQLite when absent on the Python object, and as their
actual value when present.** This is the same GLS-optionality
guarantee already tested at the model/mapper level (TASK-005) — this
task extends that guarantee through the persistence layer. Do not
substitute `NULL` with `0`, `""`, or any other placeholder for any
optional column.

## Out of scope

Same restrictions as TASK-006: no business logic, no generic ORM
layer, no touching protected paths, no added infrastructure beyond
a plain `sqlite3` connection.

Additionally: do not implement any query that filters or interprets
by `gls_value` (e.g. "get all measurements with significant GLS
decline") — that is `AlertEngine`/`RiskEngine` territory (protected),
not a repository concern. This repository only stores and retrieves
records as-is.

## Acceptance criteria

- [ ] Same core criteria as TASK-006 (`get_by_id`, `save` append-only,
      `list_by_patient` stable order, round-trip test).
- [ ] Explicit test: save a measurement with `gls_value=None` and all
      other optional fields `None` → `get_by_id` returns an object
      with those same fields `None` (not `0`, not missing attribute
      error, not any other value).
- [ ] Explicit test: save a measurement with all optional fields
      populated → `get_by_id` returns them unchanged.
- [ ] Unit tests in
      `tests/oncocardio/repository/sqlite/test_imported_echo_measurement_repository.py`.
