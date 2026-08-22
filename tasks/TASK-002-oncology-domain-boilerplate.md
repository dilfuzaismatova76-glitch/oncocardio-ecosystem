# TASK-002: OncoCardio Non-Clinical Domain Models — Boilerplate

## Reference
- docs/domain/oncocardio-domain-model-v1.md, sections 1 and 2
  ("Identity boundary", "Oncology & therapy")

## Scope

Implement the following as Pydantic models (or `@dataclass` with
manual validation if the team prefers — pick one style consistently
across the file) in `oncocardio/domain/oncology.py`:

- `PatientRef` (just `patient_uuid: UUID`)
- `CancerDiagnosis`
- `CancerTherapyPlan`
- `TherapyRegimenComponent`
- `TherapyCycle`

Use exactly the fields and types listed in the domain doc sections 1
and 2. Status fields (`status: active | in_remission | resolved`,
etc.) as Python `Enum`s with exactly the listed values.

Include:
- `id: UUID` on every entity (default via `uuid4` factory).
- Standard `created_at: datetime` audit field on every entity
  (not explicitly listed in the doc, but implied by the
  immutability/append-only principle — add it as
  `default_factory=datetime.utcnow`).

## Out of scope

- No persistence/repository code — this task is pure in-memory model
definitions.
- No business logic (no cumulative-dose calculation, no status
  transition methods beyond what's structurally implied by the enum)
  — if you find yourself writing an `if` statement that encodes a
  clinical or workflow rule, stop and flag it instead of guessing.
- Do not invent additional fields beyond the spec (e.g. do not add
  `notes`, `attachments`, or similar) even if they seem obviously
  useful — flag to architect instead.

## Acceptance criteria

- [ ] All five entities instantiate with valid data.
- [ ] `TherapyCycle.cumulative_dose_to_date` and
      `TherapyRegimenComponent.planned_cumulative_dose` accept
      `Optional[float]` (not every regimen tracks cumulative dose —
      e.g. non-anthracycline agents may not).
- [ ] Enum fields reject values outside the listed set.
- [ ] Unit tests in `tests/oncocardio/domain/test_oncology.py` cover
      valid construction and enum rejection for each entity.
