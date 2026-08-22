# TASK-004: Repository & PatientRegistryClient Abstract Interfaces

## Reference
- docs/architecture/ADR-001-app-independence.md
- docs/architecture/ADR-002-patient-registry.md
- docs/architecture/ADR-007-identity-matching-vs-merge.md

## Scope

Define **abstract interfaces only** (Python `Protocol` or `abc.ABC`,
pick `Protocol` for structural typing unless the team prefers ABC —
be consistent) — no implementations, no logic, no SQLite code.

In `medicalcore/repository/base.py`:
```
class Repository(Protocol):
    def get_by_id(self, entity_id: UUID) -> Any: ...
    def save(self, entity: Any) -> None: ...
    def list_by_patient(self, patient_uuid: UUID) -> list[Any]: ...
```
(Generic/typed properly — use `Generic[T]` with a type parameter for
the entity type, so concrete repositories can be e.g.
`Repository[CardiacAssessmentEvent]`.)

In `medicalcore/identity/registry_client.py`:
```
class PatientRegistryClient(Protocol):
    def resolve_or_create(self, demographics: ...) -> UUID: ...
        """Returns patient_uuid. Implementation (Phase 1: local file
        adapter) decides internally whether this creates a new
        identity or requires human confirmation of a match — this
        interface only defines the call shape, not the matching/
        merge behavior itself (see ADR-007)."""

    def get_demographics(self, patient_uuid: UUID) -> ...: ...

    def find_candidate_matches(self, demographics: ...) -> list[...]: ...
        """Pure, side-effect-free candidate matching (ADR-007) —
        returns candidates for human review, never merges."""
```

Use placeholder types (`Any`, or minimal stub dataclasses) for
`demographics` and candidate result shapes where the exact shape
isn't yet specified — mark them clearly with a `# TODO(architect):
finalize demographics shape` comment rather than guessing at real
fields (name, DOB, sex, MRN, external_ids).

## Out of scope — read this carefully

This task defines **shapes, not behavior**. Do NOT implement:
- Any actual matching algorithm (fuzzy name matching, DOB comparison,
  scoring, etc.) — `find_candidate_matches` stays an unimplemented
  interface method / raises `NotImplementedError` if you provide a
  concrete stub.
- Any merge logic whatsoever.
- Any SQLite/file-backed implementation of these interfaces.

If asked to "just make it work" beyond defining the interface, stop
and flag it back to the architect — this is a protected-path area
per `CODEOWNERS` (`medicalcore/identity/`) and implementations here
require an explicit follow-up task.

## Acceptance criteria

- [ ] `Repository` protocol is generic and importable.
- [ ] `PatientRegistryClient` protocol defines the three method
      signatures above with full type hints and docstrings.
- [ ] No concrete implementation classes are included in this PR.
- [ ] A one-paragraph note at the top of `registry_client.py`
      references ADR-002 and ADR-007 and states explicitly that
      matching may be automated but merge may never be.
