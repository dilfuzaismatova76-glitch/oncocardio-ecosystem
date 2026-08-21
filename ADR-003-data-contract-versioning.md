# ADR-003: Data Contract Design and Versioning

## Status
Accepted

## Context

`EchoExpert` and `OncoCardio` must exchange data (e.g. LVEF, GLS,
volumes) without one application accessing the other's internal
domain model or database. We need to decide what exactly is shared
between applications, and how that shared thing evolves over time
without breaking already-deployed installations that may update
independently.

## Decision

### What is shared

Only a **Data Contract**: versioned Pydantic DTOs defined in
`medicalcore/contracts/`. Internal domain models
(`EchoStudy` in EchoExpert, `ImportedEchoMeasurement` in OncoCardio)
are never shared and never imported across applications.

```
[EchoExpert]  Internal Domain Model (EchoStudy)
                     |  (mapper, lives in EchoExpert)
              Data Contract DTO (EchoStudyExport vN, in MedicalCore)
                     |
                   JSON  <-- transport detail, not the contract itself
                     |
              Data Contract DTO (same schema, deserialized)
                     |  (mapper, lives in OncoCardio)
[OncoCardio]  Internal Domain Model (ImportedEchoMeasurement)
```

The contract is transport-agnostic: JSON file exchange is the Phase 1
transport, but the DTO definition must not assume a specific
transport. Future transports (local API, clinic API, FHIR adapter)
replace only the transport, not the contract shape.

### Versioning

- Every DTO carries a `schema_version` field (e.g. `"1.2"`).
- **Additive, non-breaking changes** (new optional field) bump the
  minor version. An importer that only knows an older minor version
  handles this via **explicit tolerant-reader mode** — it must record
  that it is operating in `tolerant_minor` mode and which fields were
  ignored; this must never happen silently.
- **Breaking changes** (renamed/removed/retyped/re-scoped fields) bump
  the major version. The exporter always exports at its current
  version; it is not required to support old versions. The importer
  is responsible for an explicit adapter chain
  (`v1_to_v2_adapter`, `v2_to_v3_adapter`, ...).
- If an importer receives a major version newer than any adapter it
  has, it must **explicitly reject** the import with a clear error —
  never attempt to guess a field mapping.
- Every import records its `compatibility_mode`
  (`exact | tolerant_minor | adapted_major | rejected`) as part of
  the import's provenance (ADR-005).

### Separation from Core library versioning

Because each application bundles its own snapshot of `MedicalCore` at
build time (ADR-001), Core library version drift between applications
(e.g. EchoExpert on Core 1.4, OncoCardio on Core 1.7) is not, by
itself, a runtime compatibility problem — they don't share a process.
Data Contract versioning is the one thing that governs true runtime
compatibility between two already-installed, independently-updated
applications, and is therefore versioned and governed more strictly
than the Core library itself (see also ADR-008).

## Consequences

- Internal refactors in either application never force a change in
  the other, as long as the contract mapper keeps producing a
  conformant DTO.
- Contract evolution has an explicit, auditable compatibility mode at
  every import — no "quietly worked because the fields happened to
  line up."
- Adding a new application (e.g. `ECGExpert`) means adding a new
  contract type (`ECGStudyExport vN`) following the same rules.
