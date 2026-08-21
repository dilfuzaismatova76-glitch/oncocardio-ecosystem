# ADR-001: Independent Applications, Shared Minimal Core

## Status
Accepted

## Context

The ecosystem must support `EchoExpert` (echocardiography) and
`OncoCardio` (cardio-oncology CDSS) as separate products, with room for
future applications (`ECGExpert`, `HolterExpert`, `VascularExpert`)
without redesigning the foundation. Options considered:

- **A.** One large monolithic executable.
- **B.** Two fully independent executables with no shared code.
- **C.** Several independent executables + a shared Core library.
- **D.** Desktop apps + local API service.
- **E.** Desktop apps + directly shared database.

A (monolith) mixes unrelated user workflows and violates separation of
concerns. B (no shared code) guarantees duplicated clinical logic
(unit conversion, indexing, calculations) and model drift between
apps. E (shared DB written by multiple apps) creates hidden coupling
and cross-app schema risk without the discipline of a real contract.
D adds operational complexity (extra process, networking, auth) not
justified for a single-workstation desktop MVP.

## Decision

Adopt **C**, with **D as a future evolution of the transport layer only**
(see ADR-003, ADR-009 roadmap).

```
                MedicalCore (shared library, bundled per exe)
                       |
        +---------------------------+
        |                           |
   EchoExpert.exe              OncoCardio.exe
   (own UI, own DB)            (own UI, own DB)
```

- Each application is a standalone `.exe` with its own UI and own
  SQLite database.
- `MedicalCore` is a shared Python library, statically bundled into
  each executable at build time (not a running shared process).
- Cross-application data exchange happens only via versioned Data
  Contract DTOs (ADR-003), never via direct database or domain-model
  access.

## Consequences

- Applications can be released and updated independently (see ADR
  on Core library versioning below).
- No application ever imports another application's internal domain
  classes.
- Adding a new application (e.g. `ECGExpert`) means adding another
  executable on top of the same `MedicalCore` + Data Contract pattern,
  without touching existing applications.
