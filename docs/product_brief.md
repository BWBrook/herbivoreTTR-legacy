# Product brief — herbivoreTTR

## One-line summary
**herbivoreTTR** is an R package for simulating coupled **plant growth (Thornley Transport Resistance model)** and **individual herbivore foraging** with nutritionally driven plant selection.

## Who it is for
Primary users:
- Ecologists and plant–herbivore researchers
- Palaeobiologists investigating megafauna impacts
- Modelers who want a reproducible R-based platform for scenario exploration

## The problem
Existing herbivore foraging models often focus on meeting total energetic demand. This project explicitly adds a **nutrient-targeting component** (non-protein vs protein energy / digestible carb vs protein proxy) that changes plant selection dynamics and enables richer questions about vegetation structure and trait selection.

## Goals (what we are building)
By v1.0, the package must support:

1. **Coupled plant–herbivore simulation**
   - Daily TTR plant updates driven by environmental conditions
   - Minute-scale herbivore movement and intake within each day
   - Herbivory modifies plant biomass pools

2. **Herbivore functional types**
   - Grazer, browser, and mixed feeder are behaviorally distinct strategies
   - Traits (gut capacity, bite size, handling time, movement costs, water needs) scale allometrically with body mass

3. **Nutritionally driven plant selection**
   - Herbivores aim for a daily nutrient-energy target (e.g., NPE:PE or DP:DC proxy)
   - This target materially affects plant choice and movement decisions

4. **Reproducible workflows**
   - `renv` for locked dependencies
   - `{targets}` pipeline for repeatable runs and output generation
   - Deterministic results under fixed seeds (within documented tolerance)

5. **Outputs suitable for analysis**
   - Daily summaries (per herbivore and/or aggregated)
   - Optional hourly/minute logs
   - Snapshot writers with stable schemas

## Non-goals (v1.0)
Explicitly out of scope unless the roadmap says otherwise:
- Herbivore demography (birth, death, reproduction) and population dynamics
- Full soil nutrient cycling and excretion feedbacks
- Calibration/parameter fitting tooling beyond basic hooks and documented parameters
- A full GUI; this is a package + scripts + vignettes

## Constraints
- Preferred stack: R 4.5.2, `renv`, `pak`, `targets`, `testthat`, `dplyr`
- License: MIT
- Cross-platform: Linux/macOS/Windows (WSL acceptable)
- CI must run without secrets and without external paid services

## What “success” looks like
- A new user can install and run a small scenario from `README.md` and reproduce the same outputs.
- CI enforces correctness (tests), style (lint), and reproducibility (targets smoke).
- The model produces sane outputs (non-negative biomass, finite state, plausible budgets) and failures are explainable and logged.

## Deliverables
- R package with documented public API
- Two user vignettes (intro + multi-day/scenario)
- Targets pipeline that produces a small set of reference outputs
- Release artefacts: tagged versions, changelog, built tarball, and reference scenario outputs
