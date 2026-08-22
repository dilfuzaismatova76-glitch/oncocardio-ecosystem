# TASK-001: EchoStudyExport v1 — Pydantic DTO

## Reference
- docs/architecture/ADR-003-data-contract-versioning.md
- docs/domain/echostudy-export-v1.md  (THE spec — implement exactly this,
  nothing more, nothing less)

## Scope

Implement the `EchoStudyExport` Pydantic model in
`medicalcore/contracts/echo_study_export.py`, `schema_version = "1.0"`,
matching every field, type, and required/optional status listed in
`docs/domain/echostudy-export-v1.md` section "Field specification".

Requirements:
- Use `pydantic.BaseModel` (Pydantic v2 style, `model_config`,
  `Field(...)`).
- All enum fields (`lvef_method`, `bsa_formula`,
  `diastolic_function_grade`, `rv_function_qualitative`) as Python
  `Enum` classes with exactly the values listed in the spec — do not
  add or remove enum members.
- `schema_version` as a `Literal["1.0"]`.
- Conditional-required fields must be enforced via a Pydantic
  validator:
  - `gls_vendor` is required if `gls_value` is present.
  - `valvular_disease_note` is required if
    `significant_valvular_disease` is `True`.
- All optional fields default to `None` — do NOT invent any other
  default (no `0`, no `"unknown"` string, no empty list). A missing
  optional field must serialize/deserialize as absent/`null`, never
  as a placeholder value.
- Add module-level docstring pointing back to
  `docs/domain/echostudy-export-v1.md` as the source of truth.

## Out of scope

- Do NOT implement the mapper from EchoExpert's internal `EchoStudy`
  model — that lives inside EchoExpert and is a separate task.
- Do NOT implement the OncoCardio-side import/adapter logic
  (`compatibility_mode` resolution, tolerant-reader behavior,
  major-version rejection) — that touches `medicalcore/contracts/`
  import-side logic and is architect-authored (see ADR-003
  versioning rules) in a follow-up task.
- Do NOT add any field not listed in the spec, even if it seems
  clinically useful — flag it to the architect instead of adding it.

## Acceptance criteria

- [ ] Model instantiates successfully with only mandatory fields set.
- [ ] Model instantiates successfully with mandatory + all optional
      fields set.
- [ ] Omitting `bsa_formula`, `lvef_method`, or any other mandatory
      field raises a `ValidationError`.
- [ ] Setting `gls_value` without `gls_vendor` raises a
      `ValidationError`.
- [ ] Setting `significant_valvular_disease=True` without
      `valvular_disease_note` raises a `ValidationError`.
- [ ] Round-trip test: `model.model_dump_json()` →
      `EchoStudyExport.model_validate_json(...)` produces an
      identical object.
- [ ] A JSON payload with `schema_version` other than `"1.0"` fails
      validation (confirms the `Literal` constraint).
- [ ] Unit tests live in `tests/medicalcore/contracts/
      test_echo_study_export.py`.
