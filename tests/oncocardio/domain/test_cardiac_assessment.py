import pytest
from pydantic import ValidationError

from oncocardio.domain.cardiac_assessment import ImportedEchoMeasurement


def test_imported_echo_measurement_accepts_valid_minimal_record():
    model = ImportedEchoMeasurement(
        id="m-1",
        cardiac_assessment_event_id="event-1",
        source_export_id="export-1",
        source_study_id="study-1",
        imported_at="2026-01-01T00:00:00Z",
        compatibility_mode="exact",
        lvef_value=55.0,
        lvef_method="simpson",
        lvedv=100.0,
        lvesv=50.0,
        lvedvi=60.0,
        lvesvi=30.0,
        bsa_value=1.8,
        bsa_formula="mosteller",
    )

    assert model.gls_value is None
    assert model.significant_valvular_disease is None


def test_imported_echo_measurement_requires_vendor_when_gls_value_present():
    with pytest.raises(ValidationError, match="gls_vendor"):
        ImportedEchoMeasurement(
            id="m-2",
            cardiac_assessment_event_id="event-2",
            source_export_id="export-2",
            source_study_id="study-2",
            imported_at="2026-01-01T00:00:00Z",
            compatibility_mode="exact",
            lvef_value=60.0,
            lvef_method="simpson",
            lvedv=110.0,
            lvesv=45.0,
            lvedvi=61.0,
            lvesvi=25.0,
            bsa_value=1.9,
            bsa_formula="mosteller",
            gls_value=-18.2,
        )


def test_imported_echo_measurement_requires_note_when_significant_valvular_disease_true():
    with pytest.raises(ValidationError, match="valvular_disease_note"):
        ImportedEchoMeasurement(
            id="m-3",
            cardiac_assessment_event_id="event-3",
            source_export_id="export-3",
            source_study_id="study-3",
            imported_at="2026-01-01T00:00:00Z",
            compatibility_mode="exact",
            lvef_value=52.0,
            lvef_method="simpson",
            lvedv=95.0,
            lvesv=48.0,
            lvedvi=52.0,
            lvesvi=27.0,
            bsa_value=1.7,
            bsa_formula="mosteller",
            significant_valvular_disease=True,
        )
