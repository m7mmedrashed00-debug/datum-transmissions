# Datum — models, tests, and controlled engineering notes

Executable truth for Datum Transmission Co. R&D. GitHub holds code, models, tests, and
history; Notion holds program state; the reference shelf holds evidence. Raw DAQ data
stays OUTSIDE this repo (see data-manifests/).

## Structure
- `src/` — code and reusable functions
- `models/` — MATLAB, Simulink, Modelica, FEMM inputs
- `tests/` — unit, regression, and model-verification tests
- `configs/` — simulation and bench configurations
- `data-manifests/` — hashes, run IDs, provenance, calibration links (bytes live elsewhere)
- `results-summary/` — small plots and reduced tables only
- `docs/` — controlled engineering notes and model cards

## Rules
1. Every model entering this repo carries: purpose, units, assumptions, validity domain,
   tests, and parameter provenance (see `docs/model_card_template.md`).
2. Instructional/generic numbers never become product limits by repetition.
3. No family-specific specs, part numbers, or prices in this repo.
4. Prefer the lowest-order defensible model; escalate fidelity only against a named uncertainty.
5. No secrets, tokens, or credentials — ever.
