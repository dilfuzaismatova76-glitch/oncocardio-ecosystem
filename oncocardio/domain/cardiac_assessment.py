from __future__ import annotations

from typing import Literal, Optional

from pydantic import BaseModel, ConfigDict, Field, model_validator


class ImportedEchoMeasurement(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str
    cardiac_assessment_event_id: str
    source_export_id: str
    source_study_id: str
    imported_at: str
    compatibility_mode: Literal["exact", "tolerant_minor", "adapted_major", "rejected"]

    lvef_value: float
    lvef_method: str
    lvedv: float
    lvesv: float
    lvedvi: float
    lvesvi: float
    bsa_value: float
    bsa_formula: Literal["dubois", "mosteller", "other"]

    gls_value: Optional[float] = None
    gls_vendor: Optional[str] = None
    lvmi: Optional[float] = None
    rwt: Optional[float] = None
    lavi: Optional[float] = None
    diastolic_function_grade: Optional[Literal["normal", "grade_1", "grade_2", "grade_3", "indeterminate"]] = None
    e_over_e_prime: Optional[float] = None
    tapse: Optional[float] = None
    rv_function_qualitative: Optional[Literal["normal", "mildly_reduced", "moderately_reduced", "severely_reduced"]] = None
    significant_valvular_disease: Optional[bool] = None
    valvular_disease_note: Optional[str] = None
    pericardial_effusion: Optional[bool] = None

    @model_validator(mode="after")
    def validate_conditional_fields(self):
        if self.gls_value is not None and not self.gls_vendor:
            raise ValueError("gls_vendor is required when gls_value is present")

        if self.significant_valvular_disease is True and not self.valvular_disease_note:
            raise ValueError("valvular_disease_note is required when significant_valvular_disease is True")

        return self
