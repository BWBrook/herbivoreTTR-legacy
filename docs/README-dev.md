# Developer Quickstart (herbivoreTTR)

This is a concise, practical guide for collaborators to bootstrap the project environment, run tests, execute the minimal {targets} pipeline, and generate parity CSVs for C++ vs R comparisons.

## 1) Environment bootstrap with renv

In a fresh R session at the project root:

```r
# 1. Initialise base options and helper functions
source("R/packages.R")
source("R/options.R")

# 2. Bootstrap renv (restore if lockfile present; else init)
bootstrap_renv("restore")
# If no lockfile exists, instead run: bootstrap_renv("init")

# 3. Verify renv state
renv::status()
```

Notes:
- The renv autoloader prefers pak for installation (fast solver) by default.
- If you need to update packages, use `renv::install()` and then `renv::snapshot()`.

## 2) Run tests (fast smoke)

```r
# Run all tests
if (!requireNamespace("testthat", quietly = TRUE)) renv::install("testthat")
testthat::test_dir("tests/testthat", reporter = "summary")
```

Key coverage:
- Unit helpers (trap1/trap2/monod, resistances, transport)
- Herbivore–plant interface (kg↔g intake, browser filter)
- TTR orchestrator daily update
- Spin-up gating and post-spin-up activation
- IO writers header/format validation

## 3) Run minimal {targets} pipeline

```r
# Run a short simulation and write parity CSVs for day 1 and day 7
targets::tar_make()

# Inspect raw outputs + canonical bundle
list.files("data/outputs", full.names = TRUE)
list.files("artefacts/canonical_runs/smoke_v0", full.names = TRUE)
```

- Outputs include `plants_dayXYZ.csv` and `herb_dayXYZ.csv` with semicolon delimiters.
- Canonical smoke artefacts are written to `artefacts/canonical_runs/smoke_v0/` with `run_manifest.json`.
- Output schema and required columns are documented in `docs/output_contract_v0.md`.

## 4) Parity checks (optional)

```r
# Simple header + diff check in R (or use your shell)
readLines("data/outputs/plants_day1826.csv", n = 1)
# Shell example (Unix):
# diff -u data/outputs/plants_day1826.csv /path/to/cpp/plants_day1826.csv
```

## 5) Determinism and seeds

- Global RNG settings live in `R/options.R` via `init_project_options()`.
- Call it at session start for consistent RNG:

```r
init_project_options()
```

## 6) Switching herbivory and spin-up

- Control flags live in `R/constants.R`:
  - `CONSTANTS$HERBIVORY` (0/1): enables herbivore loop in daily runner.
  - `CONSTANTS$SPIN_UP_LENGTH` (years): plant-only period at simulation start.

## 7) Closure tests and verification protocol

See `docs/closure_tests.md` for structured unit + integration checks, determinism tests, and troubleshooting tips.

## 8) Continuous Integration

- GitHub Actions is enabled via `.github/workflows/ci.yml`.
- Ensure `renv.lock` is current before pushing to keep CI reproducible.
