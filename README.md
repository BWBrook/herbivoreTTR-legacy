# herbivoreTTR

Coupled plant–herbivore simulation in R: a Thornley Transport Resistance (TTR) plant growth model linked to an individual-based herbivore foraging model with nutrient-targeted plant selection.

## Status
This is research software under active development. See `CHANGELOG.md` and `docs/roadmap.md` for current progress and planned milestones.

## Installation

### Option A — Reproducible project setup (recommended)
Use `renv` to reproduce the development environment:

```r
install.packages("renv")
Sys.setenv(RENV_CONFIG_PAK_ENABLED = "FALSE")
renv::restore(prompt = FALSE)
```

Then install the package locally:

```r
install.packages("devtools")
devtools::install(dependencies = TRUE)
```

### Option B — Install from source (no renv)

From the repository root:

```r
install.packages(".", repos = NULL, type = "source")
```

## Quickstart (Scenario Workflow)

```r
library(herbivoreTTR)

# 1) Load the canonical smoke scenario contract
scenario_path <- scenario_contract_reference_path("canonical_smoke_v1")
scenario <- compile_scenario_yaml_v2(scenario_path)

# 2) Execute and write canonical artefacts
run <- run_scenario_v2(scenario)

# 3) Inspect outputs
run$run_dir
read.csv(run$daily_output_path)
read.csv(run$structure_fuel_path)
```

Canonical outputs are written under:
- `artefacts/canonical_runs/<scenario_slug>/`
- `run_manifest.json` (schema version, package version, git SHA, seed, parameter hash)
- output tables (`plants_day*.csv`, `herbivore_daily.csv`, `structure_fuel_daily.csv`)

## Non-Coder Quickstart (Portal Workflow)

The recommended non-coder entrypoint is the dedicated `portal/` folder.

1. Pick a template YAML:
- `portal/plans/templates/single_scenario_template.yaml`
- `portal/plans/templates/sensitivity_template.yaml`

2. Edit YAML only (no R code required).

3. Run with one command:

```bash
Rscript portal/run_plan.R portal/plans/templates/single_scenario_template.yaml
```

Sensitivity run:

```bash
Rscript portal/run_sensitivity.R portal/plans/templates/sensitivity_template.yaml
```

Optional GUI stub:

```bash
Rscript portal/launch_gui_stub.R
```

See:
- `portal/README.md`
- `docs/contracts/portal_plan_contract_v2.md`
- `docs/guides/ecologist_quickstart_v1.md`

## Running The Targets Pipeline

The repository includes a `{targets}` pipeline (`_targets.R`) that generates canonical smoke outputs, reference scenarios, experiments A/B/C, benchmark appendix artefacts, and the paper skeleton report.

```r
install.packages("targets")
targets::tar_make()
```

To run a minimal “CI-style” pipeline locally, set a targets profile:

```r
Sys.setenv(TARGETS_PROFILE = "ci")
targets::tar_make(callr_function = NULL)
```

## Outputs

Depending on the runner and options, outputs include:

* `plants_day*.csv` plus either `herbivore_daily.csv` (explicit modes) or `pressure_daily.csv` (implicit pressure mode)
* `structure_fuel_daily.csv` (derived vegetation structure/fuel metrics)
* optional minute/hourly diagnostics for behavioural contract scenarios
* run manifests for all canonical scenarios and experiments

See `docs/architecture.md` for state object schemas and invariants.
See `docs/reference/parameter_units_reference.md` for parameter defaults, units, and cited allometric relationships.
See `docs/contracts/output_contract_v1.md` for low-level snapshot schema details.
See `docs/contracts/scenario_run_output_contract_v2.md` for scenario-run bundle output semantics.
See `docs/contracts/scenario_contract_v2.md` for the primary scenario YAML schema.
See `docs/governance/api_surface_v2.md` for the current public API surface.
See `docs/governance/deprecation_policy.md` for compatibility and deprecation guarantees.

## Reproducibility

* Dependencies are pinned in `renv.lock`.
* The simulation is designed to be deterministic under a fixed seed (within documented tolerances).

## Contributing

Developer workflow and quality gates are described in:

* `AGENTS.md` (autonomous engineering harness)
* `docs/README.md` (documentation map and folder index)
* `docs/workflow.md` (result/artefact review cycle)
* `docs/decisions.md` (scientific and architectural decisions)

## License

MIT (see `LICENSE`).
