# TASK-006: SQLite Repository — Oncology Entities

## Assigned to
MAI-Code (implementation assistant tier — see
docs/architecture/model-assignment-policy.md).
Non-protected path — no architect pre-approval needed before starting,
but architect review is still required before merge (standard PR flow).

## Reference
- docs/architecture/ADR-001-app-independence.md (own SQLite DB per app)
- docs/architecture/ADR-006-immutability-and-corrections.md
  (append-only clinical tables)
- docs/domain/oncocardio-domain-model-v1.md, section 2
- TASK-002 (depends on) — entities: `CancerDiagnosis`,
  `CancerTherapyPlan`, `TherapyRegimenComponent`, `TherapyCycle`
- TASK-004 (depends on) — `Repository[T]` protocol in
  `medicalcore/repository/base.py`

## Scope

Implement SQLite-backed repositories for the four oncology entities
in `oncocardio/repository/sqlite/`, one file per entity:
- `cancer_diagnosis_repository.py`
- `cancer_therapy_plan_repository.py`
- `therapy_regimen_component_repository.py`
- `therapy_cycle_repository.py`

Each class implements the `Repository[T]` protocol
(`get_by_id`, `save`, `list_by_patient`) using Python's built-in
`sqlite3` module (no ORM — this matches the project's current stack
decision; do not introduce SQLAlchemy).

Requirements:
- `save()` is **append-only** for these entities: if a row with the
given `id` already exists, `save()` must raise a
`ValueError("Entity <id> already exists — records are immutable,
use a correction workflow instead")` rather than overwriting it.
This enforces ADR-006 at the repository layer, not just by
convention.
- Table schema (columns) mirrors the Pydantic model fields exactly —
  no additional columns, no renamed columns.
- Use parameterized queries only (`?` placeholders) — never string-
  formatted SQL, to avoid injection and because it's simply correct
  practice.
- Each repository file includes a `CREATE TABLE IF NOT EXISTS ...`
  schema definition as a module-level constant or an `init_schema()`
  function — do not silently assume the table exists.
- Serialize UUID fields as `TEXT` (str(uuid)), datetime/date fields as
  ISO-8601 `TEXT`, enums as their `.value` (TEXT).

## Out of scope

- Do NOT implement any business logic (e.g. do not compute
  `cumulative_dose_to_date` inside the repository — it is passed in
  already-computed, per TASK-002's own out-of-scope note; if that
  computation doesn't exist yet, that's a separate, architect-defined
  task, not something to improvise here).
- Do NOT implement a generic/abstract SQLite base class beyond what's
  needed — four small, explicit, readable files are preferred over
  a clever generic engine (avoid over-abstraction per project
  principles).
- Do NOT touch `medicalcore/identity/`, `oncocardio/rules/`,
  `oncocardio/risk/`, `oncocardio/alerts/`, `oncocardio/monitoring/`,
  `oncocardio/provenance/`, or any `docs/` path — if you believe a
  change there is needed to complete this task, stop and flag it back
  to the architect instead of proceeding.
- Do NOT add a database connection pool, migration tool, or
  configuration system — accept a `db_path: str` or an existing
  `sqlite3.Connection` in each repository's constructor; keep it
  simple for MVP (ADR scope discipline).

## Acceptance criteria

- [ ] All four repositories implement `get_by_id`, `save`,
      `list_by_patient` per the `Repository[T]` protocol.
- [ ] `save()` on an existing id raises `ValueError` and does not
      modify the row (verify by re-reading afterward).
- [ ] `get_by_id` on a non-existent id raises a clear, explicit
      exception (not a silent `None` return) — pick and document one
      pattern (e.g. `KeyError`) and use it consistently across all
      four repositories.
- [ ] `list_by_patient` returns entities in a stable order (e.g. by
      `created_at`) — specify and test the order.
- [ ] Round-trip test per entity: save → get_by_id → resulting object
      equals the original (field-by-field).
- [ ] Tests use an in-memory SQLite DB (`sqlite3.connect(":memory:")`)
      — no test writes to a file on disk.
- [ ] Unit tests in
      `tests/oncocardio/repository/sqlite/test_<entity>_repository.py`,
      one file per entity, mirroring the structure above.
