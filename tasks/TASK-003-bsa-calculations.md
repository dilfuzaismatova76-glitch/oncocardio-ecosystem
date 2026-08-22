# TASK-003: BSA Calculation Functions (Category B — pure math)

## Reference
- docs/architecture/ADR-004-clinical-rules-classification.md
  (Category B: mathematical calculations = code, named + versioned
  functions)
- docs/domain/echostudy-export-v1.md (`bsa_formula` enum:
  `dubois` | `mosteller` | `other`)

## Scope

Implement in `medicalcore/calculations/bsa.py`:

```
def bsa_dubois_v1(height_cm: float, weight_kg: float) -> float:
    """Du Bois & Du Bois (1916): BSA = 0.007184 * height^0.725 * weight^0.425"""

def bsa_mosteller_v1(height_cm: float, weight_kg: float) -> float:
    """Mosteller (1987): BSA = sqrt((height_cm * weight_kg) / 3600)"""
```

These exact formulas are specified here by the architect — do not
substitute, "improve", or adjust coefficients. Per ADR-008: if a
formula ever needs to change, it becomes a new function
(`bsa_dubois_v2`), never an edit to `bsa_dubois_v1`'s body.

Both functions:
- Return BSA in m².
- Raise `ValueError` for non-positive `height_cm` or `weight_kg`
  (invalid input, not a clinical judgment call — this is basic input
  validation).
- Include the formula and citation in the docstring (as shown above).

## Out of scope

- No formula selection/decision logic (which formula to use when) —
  that's a downstream concern for whatever calls this, driven by
  `bsa_formula` recorded on the relevant measurement, not by this
  module.
- Do not add other BSA formulas (Haycock, Gehan-George, etc.) unless
  explicitly requested — don't anticipate future needs here.

## Acceptance criteria

- [ ] `bsa_dubois_v1(170, 70)` and `bsa_mosteller_v1(170, 70)` produce
      results matching hand-calculated reference values (within
      floating point tolerance, e.g. `pytest.approx(..., rel=1e-4)`).
- [ ] Both functions raise `ValueError` for `height_cm=0`,
      `weight_kg=0`, and negative inputs.
- [ ] Unit tests in `tests/medicalcore/calculations/test_bsa.py`
      include at least 3 reference value pairs per formula (use
      published reference examples, cite the source in a test
      comment).
