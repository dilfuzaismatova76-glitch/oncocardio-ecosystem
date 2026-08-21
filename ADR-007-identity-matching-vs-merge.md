# ADR-007: Identity Matching vs. Merge

## Status
Accepted

## Context

Applications must be able to recognize when a patient being entered
already exists in the Patient Registry (ADR-002), without risking an
incorrect automatic merge of two different patients' clinical
histories — a direct patient-safety hazard.

## Decision

Two distinct operations are defined, with different levels of
automation:

- **Matching** — computing candidate matches for "this might be the
  same patient" based on available evidence (name, date of birth, sex,
  MRN, DICOM PatientID, other `external_ids`). This is a pure,
  side-effect-free function and **may be automated**.
- **Merge** — the irreversible act of treating two records as
  referring to the same patient. This is **never automatic**. It
  requires explicit confirmation by a physician/operator through the
  UI, and the merge action itself is logged as an audit event (who,
  when, on what evidence).

```
patient_uuid
    is the ONLY internal identity, assigned solely by the
    Patient Registry.

MRN, DICOM PatientID, FHIR id, name+DOB, phone, etc.
    are matching evidence / external identifiers ONLY.
    None of them is ever used as an internal primary key,
    regardless of how reliable it appears to be in a given
    clinic's setup.
```

Typical flow when a new patient is entered in one application and a
plausible match exists in the Registry:

```
"Possible existing patient match"
  Ivanov Ivan Ivanovich, 12.03.1972
  Candidate: Ivanov I. I., 12.03.1972
  [ This is the same patient ]   [ This is a different patient ]
```

No automatic silent merge occurs under any circumstance, including
exact MRN match — MRN reliability depends on external systems the
ecosystem does not control.

## Consequences

- A wrong match only ever surfaces as a *suggestion*; the
  safety-critical action (merge) always has a human in the loop and an
  audit trail.
- `medicalcore/identity/` and `oncocardio/identity/` are protected
  paths (see `CODEOWNERS`) — no implementation assistant introduces or
  modifies matching/merge logic without an explicit architect-approved
  task.
