# herbivoreTTR

Coupled plant–herbivore simulation in R: a Thornley Transport Resistance (TTR) plant growth model linked to an individual-based herbivore foraging model with nutrient-targeted plant selection.

## Status
This is research software under active development. See `CHANGELOG.md` and `docs/roadmap.md` for current progress and planned milestones.

## Installation

### Option A — Reproducible project setup (recommended)
Use `renv` to reproduce the development environment:

```r
install.packages("renv")
renv::restore(prompt = FALSE)
````

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

## Quickstart

```r
library(herbivoreTTR)

# 1) Initialize a simple coupled system
sim <- init_simulation(temp_mode = "flat", herbivore_mass = 5e5, herb_type = 0)

# 2) Run a short multi-day simulation (small minute_limit for speed)
res <- run_herbivore_days(days = 3, minute_limit = 60)

# Inspect daily summaries
print(res$daily_summary)
```

## Running the targets pipeline

The repository includes a `{targets}` pipeline (`_targets.R`) that generates small reference artefacts (e.g., snapshot CSVs).

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

* Daily summary tables (energy/water balance, intake, movement)
* Optional hourly/minute logs for debugging and analysis
* Plant and herbivore snapshot CSVs (stable-schema artefacts intended for downstream analysis)

See `docs/architecture.md` for state object schemas and invariants.

## Reproducibility

* Dependencies are pinned in `renv.lock`.
* The simulation is designed to be deterministic under a fixed seed (within documented tolerances).

## Contributing

Developer workflow and quality gates are described in:

* `AGENTS.md` (autonomous engineering harness)
* `docs/workflow.md` (result/artefact review cycle)
* `docs/decisions.md` (scientific and architectural decisions)

## License

MIT (see `LICENSE`).
