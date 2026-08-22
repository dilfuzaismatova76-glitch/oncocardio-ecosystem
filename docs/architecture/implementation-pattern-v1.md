# Implementation Pattern v1

## Status
Accepted as the project-level implementation reference for the current
specification phase. This is not an ADR in the clinical/architectural
sense; it is an operational standard for how generated code and
reviewed patches must be shaped across the project.

## Reference
- ADR-000 (roles and workflow)
- ADR-003 (data contract and versioning)
- ADR-004 (rule classification)
- ADR-006 (immutability and corrections)
- ADR-007 (identity matching vs merge)
- `CODEOWNERS`
- `docs/architecture/model-assignment-policy.md`
- `tasks/TASK-001-echostudyexport-dto.md`
- `tasks/TASK-002-oncology-domain-boilerplate.md`
- `tasks/TASK-003-bsa-calculations.md`
- `tasks/TASK-004-repository-interfaces.md`
- `tasks/TASK-005-imported-echo-measurement-mapper.md`
- `tasks/TASK-006-sqlite-repository-oncology.md`
- `tasks/TASK-007-sqlite-repository-imported-echo.md`

## Purpose

This document resolves the real ambiguities that surfaced during
review and locks the canonical layer boundaries before implementation
continues. It is intentionally narrower than a general coding style
guide: it is the project-specific rulebook for how to implement the
approved tasks without violating ADR decisions or mixing architectural
layers.

---

## 1. Canonical layer boundaries

### 1.1 Contracts and domain entities: Pydantic v2
Use `pydantic.BaseModel` for:
- DTO contracts that define an external boundary (for example,
  `EchoStudyExport`)
- domain entities that are part of the application model (for example,
  the oncology entities and `ImportedEchoMeasurement`)

Rules:
- `model_config = {"extra": "forbid"}` where the model is a frozen
  domain boundary
- `Field(...)` for required values
- `default=None` only for actual optional values
- Exact enum members only; do not widen or silently coerce values
- Conditional validation remains enforced exactly as specified by the
  task and the domain document

This applies to contracts and domain entities, not to all project
components indiscriminately.

### 1.2 Interfaces: Protocols, not Pydantic models
Use `typing.Protocol` for:
- `Repository[T]`
- `PatientRegistryClient`

Reason:
- This is structural typing by design, not runtime validation of DTOs
- It intentionally avoids runtime data coercion while preserving
  interface-level contracts
- This is already the project decision in TASK-004 and should not be
  changed by later implementation work

Do not rewrite these interfaces into Pydantic models or ORM-backed
abstractions. That would not be an improvement; it would be a layer
violation.

### 1.3 Persistence: plain sqlite3, not ORM and not Pydantic-heavy layer
Use Python's built-in `sqlite3` module for repository implementation
per TASK-006 and TASK-007.

Reason:
- the project explicitly chose this stack direction
- no ORM is introduced by default
- repository code is persistence plumbing, not a model-definition zone
- the repository is not the place for clinical interpretation or
  domain policy beyond invariant enforcement

Do not add an ORM layer, generic abstraction engine, or broad
Pydantic wrappers to repository code unless a new architect-approved
task explicitly changes this decision.

---

## 2. Data-integrity invariants vs business logic

This distinction is mandatory and must be enforced in review.

### 2.1 Business logic is forbidden in repositories
The repository layer must not do any of the following:
- calculate clinically meaningful values from raw inputs
- interpret measurements, thresholds, or alert severity
- decide which formula is appropriate for a patient
- perform matching or merge logic for identity resolution
- invent clinical rules or policy decisions

This is the meaning of "no business logic in repository layer" in the
project standards.

### 2.2 Data-integrity invariants are required in repositories
The repository layer must enforce project invariants that are part of
storage safety, not interpretation:
- append-only semantics for immutable records
- duplicate-id rejection for existing records
- explicit exception behavior for missing id
- stable ordering for list retrieval when required by task contract
- exact persistence semantics for optional fields (``None`` ↔ ``NULL``)

This is not business logic; it is integrity enforcement.

### 2.3 Review rule
If a repository implementation starts computing domain state, deciding
clinical meaning, or reinterpreting the meaning of a value, it is out
of scope. If it enforces safe storage semantics, it is in scope.

This distinction is the reason ADR-006 is enforceable at the
repository layer without violating the "no business logic" rule.

---

## 3. Optional field semantics across all layers

The project standard is not just "optional fields in DTO are None".
The standard is: end-to-end optional semantics across all layers.

### 3.1 Rule
- in Python domain objects: absent optional values are `None`
- in SQLite persistence: absent optional values are `NULL`
- no placeholder substitutes such as `0`, `""`, `"unknown"`, or any
  empty sentinel value
- any consumer that reads a persisted record must receive the same
  meaning as the original object had when saved

This is especially important for the GLS case and related optional
fields in `ImportedEchoMeasurement` and the echo export contract.

If the optional field is absent, the system must preserve absence as
absence. It must not silently normalize it into a default value.

### 3.2 Applicable fields
The general rule applies to all optional fields, including:
- `gls_value`, `gls_vendor`
- `lvmi`, `rwt`, `lavi`
- `diastolic_function_grade`, `e_over_e_prime`
- `tapse`, `rv_function_qualitative`
- `significant_valvular_disease`, `valvular_disease_note`
- `pericardial_effusion`

These are protected by the same semantics at DTO, domain, and
persistence layers.

---

## 4. Conditional validation and defense in depth

### 4.1 Rule for the DTO layer
Conditional validation remains mandatory in the DTO and any domain
boundary that is directly user-written or externally supplied.

This includes the specific requirements from TASK-001:
- `gls_vendor` required when `gls_value` is present
- `valvular_disease_note` required when
  `significant_valvular_disease` is `True`

### 4.2 Rule for the domain layer
The same conditional validation should also be preserved in the domain
model that is directly instantiated by application code or restored
from persistence, especially for `ImportedEchoMeasurement`.

Reason:
- the mapper is not the only entry point to model construction
- repository deserialization is a valid code path that may bypass the
  mapper entirely
- this is a medical-data safety rule, not just a DTO convenience
  feature

### 4.3 Required implementation pattern
If a model is created or rebuilt outside the mapper flow, it must
still reject invalid combinations. This is the correct defense-in-depth
pattern for the project.

The rule is simple:
- validate at contract boundary
- validate again at domain boundary where the object is a meaningful
  clinical artifact
- do not rely on a single code path to preserve correctness

This avoids a silent assumption that "nobody will construct the object
without the mapper".

---

## 5. Assignment policy remains the routing authority

The routing matrix in `docs/architecture/model-assignment-policy.md`
remains authoritative.

In short:
- Category B math and protected clinical logic → Claude
- boilerplate and repetitive structural generation → Gemini / GPT /
  MAI-Code
- final review and merge gate remains with the architect/lead

This policy is not superseded by the implementation pattern document.
It is a complementary operational standard.

---

## 6. Canonical acceptance standard for tasks

The task files define the implementation contract, but they are not
considered automatically closed merely because they were authored.

A task is considered accepted only when all of the following are true:
- the code matches the task scope exactly
- the code respects the relevant ADR/domain doc constraints
- the tests pass in the repository environment
- there are no forbidden layer violations
- the implementation respects protected-path rules and governance

This applies especially to tasks already identified as having open
items, such as:
- TASK-003 (BSA reference values pending validation)
- TASK-004 (protocol complete only in part; registry client is still
  open as a separate implementation item)

A task file is a specification, not proof of completion.

---

## 7. Explicitly rejected patterns

The following patterns are rejected:
- forcing Pydantic onto interface or repository layers when the
  architecture explicitly chose `Protocol` and `sqlite3`
- replacing `None` with placeholder defaults in any layer
- placing clinical interpretation or policy decisions into repository
  code
- treating append-only invariants as optional conventions rather than
  enforced rules
- assuming the mapper is the only way an object can be created
- merging protected-path changes without explicit approval

---

## 8. Canonical implementation rules summary

If you need the shortest possible standard to follow, use this:

1. Model DTOs and domain entities with Pydantic v2, strict enums,
   required field validation, and no silent defaults.
2. Use `Protocol` for interfaces; do not convert interfaces into
   runtime-validated models.
3. Use plain `sqlite3` for repositories; repository code is for
   persistence, not clinical interpretation.
4. Enforce append-only and duplicate-id invariants in the repository,
   because those are data-integrity rules required by ADR-006.
5. Preserve `None` / `NULL` semantics end-to-end across DTO → domain →
   persistence.
6. Validate conditional requirements at both the DTO boundary and the
   domain boundary for safety-critical field combinations.
7. Keep all protected-path changes under explicit architect approval.
8. Treat task files as implementation specs, not as proof that a task
   is already complete.

---

## Final note

This document is deliberately written to reconcile the architecture
with the actual implementation realities of the project. It does not
remove the accepted constraints; it makes the boundaries explicit so
future generated patches do not accidentally blur them.
