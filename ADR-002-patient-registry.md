# ADR-002: Patient Registry as Single Source of Patient Identity

## Status
Accepted

## Context

If each application maintains its own patient records independently,
the ecosystem risks multiple, unlinked records for the same real
patient across `EchoExpert`, `OncoCardio`, and future applications —
a direct patient-safety risk (data exchanged or compared across
different, unmerged records of what is actually one person).

Three models were considered:

- **A.** Each application has its own patient table (no shared identity).
- **B.** A dedicated Patient Registry owns identity + demographics;
  each application keeps its own clinical domain data, referencing
  the registry by a canonical id.
- **C.** A single shared Clinical DB, applications as thin clients.

A does not scale safely across a growing set of applications. C
collapses application independence (ADR-001) and requires a
client-server architecture from day one, which is premature for the
desktop MVP. B preserves application independence while giving a
single, canonical source of identity.

## Decision

Adopt **B**.

```
                    Patient Registry
                          |
                     patient_uuid
                          |
        +------------------+------------------+
        |                                     |
   EchoExpert.exe                       OncoCardio.exe
   (references patient_uuid)            (references patient_uuid)
```

- On Phase 1 (single workstation), the Patient Registry is a separate
  local SQLite file, shared by all ecosystem applications installed on
  that machine.
- Applications access it only through a `PatientRegistryClient`
  interface defined in `MedicalCore` (ADR-005 boundaries). The Phase 1
  implementation is a direct local-file adapter; later phases
  (clinic-wide, centralized) swap the adapter behind the same
  interface — see roadmap in ADR-009.
- The Registry owns: `patient_uuid` (canonical identifier),
  demographics (name, date of birth, sex), and `external_ids`
  (MRN, DICOM PatientID, future FHIR id, etc. — evidence, not identity;
  see ADR-007).
- No application creates patient identity on its own; every
  application requests identity resolution/creation from the Registry.

## Consequences

- A patient can only physically have one canonical record in the
  ecosystem; "five unlinked records of the same patient" becomes
  structurally impossible, not just discouraged.
- The Registry's storage mechanism (local file vs. network service) is
  an implementation detail behind a stable interface — changing it
  later does not require changes in `EchoExpert` or `OncoCardio`.
- Demographics are the one category of data that may be legitimately
  corrected (name spelling, DOB) over time — see ADR-007 for how this
  interacts with identity and ADR-006 for correction handling.
