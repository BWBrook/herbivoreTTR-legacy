# Reference Scenario Library v1

This index tracks the curated scenario set used for reference experiments and
paper-pipeline summaries.

Source YAML definitions:
- `config/scenarios/reference_presence_present_v1.yaml`
- `config/scenarios/reference_presence_removed_v1.yaml`
- `config/scenarios/reference_grazer_v1.yaml`
- `config/scenarios/reference_browser_v1.yaml`
- `config/scenarios/reference_mixed_v1.yaml`
- `config/scenarios/reference_aridity_low_v1.yaml`
- `config/scenarios/reference_aridity_mid_v1.yaml`
- `config/scenarios/reference_aridity_high_v1.yaml`

## Core curated set (WP-0.6.2)

| Scenario | Purpose | Expected qualitative outcome |
|---|---|---|
| `reference_presence_present_v1` | Herbivore-present treatment baseline | Lower final structure/fuel metrics than removal scenario |
| `reference_presence_removed_v1` | Herbivore-removed counterfactual | Higher final structure/fuel metrics than present scenario |
| `reference_grazer_v1` | Grazer strategy reference | Higher grass-share intake than browser |
| `reference_browser_v1` | Browser strategy reference | Higher woody-share intake than grazer |
| `reference_mixed_v1` | Mixed-feeder strategy reference | Intermediate intake partition between grazer and browser |

## Experiment-specific gradient set (WP-0.6.5)

| Scenario | Purpose | Expected qualitative outcome |
|---|---|---|
| `reference_aridity_low_v1` | Low-stress climate point | Lower drinking demand, higher retained vegetation |
| `reference_aridity_mid_v1` | Intermediate climate point | Intermediate activity and vegetation response |
| `reference_aridity_high_v1` | High-stress climate point | Higher drinking demand, lower retained vegetation |

## Artefact index outputs

Generated scenario library index artefacts:
- `artefacts/canonical_runs/reference_scenarios_v1/reference_scenarios.csv`
- `artefacts/canonical_runs/reference_scenarios_v1/reference_scenarios_index.md`
