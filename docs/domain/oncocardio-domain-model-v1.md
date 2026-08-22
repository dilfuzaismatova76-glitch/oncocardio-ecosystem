# OncoCardio Domain Model v1

## Status
Draft v1 — frozen pending first implementation pass.

## Reference
All ADR-000 through ADR-008. This document does not restate their
reasoning — it operationalizes them into a concrete entity model.

## Scope note

This is the OncoCardio-internal domain model. It never imports or
depends on EchoExpert's internal model — the only echo data entering
this model arrives via `EchoStudyExport` (see
`echostudy-export-v1.md`) and is mapped into `ImportedEchoMeasurement`
below.

---

## 1. Identity boundary

`Patient` itself is **not** an OncoCardio entity — identity and
demographics live in the Patient Registry (ADR-002). OncoCardio holds
only a reference:

```
PatientRef
  patient_uuid          (from Patient Registry, immutable)
```

Everything below hangs off `patient_uuid`, never off a locally-owned
patient record.

---

## 2. Oncology & therapy

```
CancerDiagnosis
  id, patient_uuid
  diagnosis_code (e.g. ICD-O / free text pending coding-system decision)
  diagnosis_date
  status: active | in_remission | resolved   (versioned via status
                                               transitions, not deletion)

CancerTherapyPlan
  id, cancer_diagnosis_id
  planned_at
  status: planned | active | completed | discontinued

TherapyRegimenComponent
  id, therapy_plan_id
  drug_name
  drug_class                       (used to look up cardiotoxicity
                                     profile + monitoring protocol,
                                     ADR-004 category E)
  planned_cumulative_dose          (if applicable, e.g. anthracyclines)
  route, schedule_description

TherapyCycle
  id, therapy_regimen_component_id
  cycle_number
  administered_at
  actual_dose
  cumulative_dose_to_date          (append-only running total,
                                     recomputed from history, not
                                     hand-edited)
```

**Owner:** OncoCardio (ADR domain ownership table). Immutable once a
cycle is recorded as administered; corrections follow ADR-006
(correction event, not edit).

---

## 3. Cardiovascular risk

```
RiskFactorRecord            (immutable, timestamped fact)
  id, patient_uuid
  factor_type: hypertension | diabetes | dyslipidemia |
               prior_cv_disease | smoking | obesity | age_derived | ...
  value / presence
  recorded_at
  source: physician_entered | derived

RiskAssessmentResult        (immutable, one per calculation run)
  id, patient_uuid
  risk_model_id, risk_model_version    (ADR-008)
  input_snapshot_ref                   (which RiskFactorRecords /
                                         measurements were used)
  output_category                      (e.g. HFA-ICOS: low / moderate /
                                         high / very high)
  provenance_summary_ref               (ADR-005)
  generated_at
```

`RiskAssessmentResult` is never "the patient's risk" — it is the
frozen output of one specific calculation at one point in time. The
*current* risk is simply the most recent result; history is preserved
in full (ADR-006 pattern applied to computed results, not just raw
facts).

---

## 4. Cardiac assessment — the central timeline entity

```
CardiacAssessmentEvent
  id, patient_uuid
  reason: baseline | pre_cycle | post_cycle | follow_up | unscheduled
  linked_therapy_cycle_id           (nullable — baseline/follow-up may
                                      not link to a specific cycle)
  scheduled_at, performed_at
  status: planned | completed | missed
```

This is deliberately the organizing node of the domain, not one
entity among many — every clinical measurement below exists *in the
context of* an assessment event, and the sequence of events **is**
the patient's longitudinal clinical timeline that the physician
navigates.

### 4a. ECG (own entity — future ECGExpert boundary honored now)

```
ECGAssessment
  id, cardiac_assessment_event_id
  source: physician_entered | imported        (imported reserved for
                                                 when ECGExpert exists;
                                                 physician_entered is
                                                 the only source today)
  heart_rate, qt_interval
  qtc_value, qtc_formula            (ADR-004 category B — formula
                                      choice is a named, versioned
                                      function, e.g. bazett_v1)
  measured_at
```

OncoCardio does **not** own a general-purpose `ECGStudy` entity — that
ownership is reserved for a future `ECGExpert`, per the domain
ownership decision made explicitly ahead of that application's
existence. `ECGAssessment` here is a narrow, cardio-oncology-specific
interpretation record, not a full ECG study.

### 4b. Imported echo measurement

```
ImportedEchoMeasurement
  id, cardiac_assessment_event_id
  source_export_id                  (ref to the EchoStudyExport that
                                      produced this record)
  source_study_id                   (EchoExpert's opaque study id)
  imported_at
  compatibility_mode                (exact | tolerant_minor |
                                      adapted_major | rejected — ADR-003)

  # Mandatory fields (mirrors EchoStudyExport mandatory section)
  lvef_value, lvef_method
  lvedv, lvesv, lvedvi, lvesvi
  bsa_value, bsa_formula

  # Optional fields — present only if the export contained them.
  # GLS in particular: if gls_value is None here, every consumer
  # (AlertEngine, RiskEngine, LongitudinalAnalysisService,
  # ReportEngine) MUST treat this timepoint as "GLS not assessed",
  # never as "GLS normal". This is a binding rule, not a default.
  gls_value: Optional
  gls_vendor: Optional
  lvmi, rwt, lavi, diastolic_function_grade, e_over_e_prime,
  tapse, rv_function_qualitative,
  significant_valvular_disease, valvular_disease_note,
  pericardial_effusion: all Optional
```

**Owner:** OncoCardio (the record itself — the source data is owned
by EchoExpert, see ownership table). Created once at import time,
never edited; a re-import (e.g. corrected echo) creates a new
`ImportedEchoMeasurement`, superseding the previous one via status,
not overwrite (ADR-006 pattern).

### 4c. Biomarkers

```
BiomarkerResult
  id, cardiac_assessment_event_id
  biomarker_type: hs_ctn | nt_probnp | bnp
  value, unit
  assay_reference_range_used        (assay-dependent — must be
                                      recorded, analogous to GLS
                                      vendor sensitivity)
  measured_at
  source: physician_entered | imported | lab_interface (future)
```

---

## 5. Longitudinal comparison (computed, not stored as a persistent entity)

```
LongitudinalComparisonResult        (computed on demand, may be
                                      cached but is not a source of
                                      truth — always re-derivable from
                                      the immutable measurement history)
  parameter_type: lvef | gls | hs_ctn | nt_probnp | qtc | ...
  baseline_value, baseline_measured_at
  previous_value, previous_measured_at
  current_value, current_measured_at
  absolute_change, relative_change
  trend                              (over N points, not just 2)
  significance_flag                  (per applicable RuleVersion)
  comparability_note                 (e.g. "GLS vendor changed since
                                       baseline — trend not directly
                                       comparable"; "GLS not assessed
                                       at this timepoint")
```

For GLS specifically: if any point in the series has no `gls_value`
(per section 4b), that point is excluded from the trend with an
explicit `comparability_note`, not interpolated or treated as
unchanged.

---

## 6. Alerts, monitoring, conclusion

```
ClinicalAlert                        (immutable, AlertEngine-only writer)
  id, cardiac_assessment_event_id
  severity: green | yellow | orange | red
  parameter, finding_description
  message                            (always "requires clinical
                                       evaluation" framing — never a
                                       diagnosis or a treatment
                                       instruction)
  provenance_summary_ref             (ADR-005)
  status: open | acknowledged_by_physician
  created_at, acknowledged_at, acknowledged_by

MonitoringPlan                       (versioned)
  id, patient_uuid
  generated_at
  based_on_ref                       (risk assessment + therapy +
                                       baseline snapshot used)
  planned_assessments: [ {reason, target_date, required_components} ]
  status: active | superseded

CardiologyConclusion                 (physician-authored)
  id, patient_uuid
  cardiac_assessment_event_id
  status: draft | signed
  content                            (system-generated draft text,
                                       editable pre-signature)
  signed_by, signed_at               (immutable once signed — a later
                                       change creates a new version,
                                       ADR-006)
```

`AlertEngine` is the only writer of `ClinicalAlert`. Nothing else in
the system — not `ReportEngine`, not manual UI action — creates one
directly, per the alert/conclusion separation established in review.

---

## 7. Provenance (cross-cutting, attached to computed entities above)

```
ProvenanceSummary                    (always present on RiskAssessmentResult,
                                       ClinicalAlert, each generated report
                                       sentence)
  source_measurement_ids
  rule_id, rule_version  (or risk_model_id, risk_model_version)
  guideline_version_ref
  engine_version
  result
  generated_at

DetailedExecutionTrace               (optional — Category C/D outputs only)
  inputs: [...]
  calculation_steps: [...]
```

See ADR-005 for the rule governing when Level 2 is recorded.

---

## Open items for next iteration

- Coding system for `CancerDiagnosis.diagnosis_code` (ICD-O vs
  free-text vs both) — not yet decided, does not block DTO/model
  work below it.
- Whether `RiskFactorRecord` needs its own correction-event pattern
  distinct from measurement corrections (likely yes, same shape).
- First concrete `RuleVersion` set for Category A alerts (LVEF/GLS/
  biomarker thresholds) — deferred to a dedicated clinical-content
  pass, not an architecture decision.
