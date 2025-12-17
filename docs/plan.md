# Development plan — herbivoreTTR

This plan is a sketch: see `docs/roadmap` for the full details. It is organized into milestones with explicit acceptance criteria and stop conditions.

## Milestone 0.1.0 — MVP: “Productionized baseline + meaningful functional types”
### Scope
- Package is check-clean and CI-gated.
- Single-herbivore coupled run is reproducible and documented.
- Grazer/browser/mixed are behaviorally distinct at least in diet choice rules.

### Must-do deliverables
- CI: R CMD check + tests + lintr + targets smoke + coverage threshold
- Dependency declarations aligned with actual test/pipeline usage
- Public API documented (export list treated as stable for v0.1.x)
- Domain sanity tests added (finite state, non-negativity, gut capacity constraints)
- README quickstart + vignette runnable on a clean install

### Acceptance criteria
- CI green on main
- `R CMD check --as-cran` is clean on Linux (and preferably macOS/Windows)
- A minimal example run generates stable-schema outputs and passes sanity checks

### Stop condition
- Three consecutive CI runs on main are green and artefact outputs are reviewed and logged.

## Milestone 0.5.0 — Beta: “Multiple herbivores + scenario configuration”
### Scope
- N herbivores (heterogeneous mass/type) supported in the coupled simulation.
- Scenarios can be defined as a structured object and optionally loaded from YAML.

### Deliverables
- Population runner + deterministic update ordering
- Scenario contract documented and tested
- Output contract extended with herbivore IDs + aggregated plot metrics
- Performance budget test for small scenarios

### Stop condition
- A reference scenario file reproduces outputs on two machines using `renv::restore()`.

## Milestone 1.0.0 — Stable research platform
### Scope
- API freeze with deprecation policy.
- Curated reference scenarios + documented expected outcomes.
- Release automation and artefact production.

### Deliverables
- v1.0 documentation set complete (README + vignettes + architecture)
- Golden outputs suite (parity or fixtures) documented and enforced
- Release checklist enforced and repeatable

### Stop condition
- External user run-through succeeds (install → run scenario → interpret outputs) without maintainer intervention.

---

## Backlog (prioritized)
### Next
- Wire config/scenario object into `_targets.R` and demo scripts
- Mixed feeder strategy: explicit policy (e.g., weighted graze/browse preference)
- Output schema versioning and documentation

### Later
- Optional calibration hooks (parameter scanning, sensitivity analysis)
- Additional climate drivers (rainfall/humidity) if needed for aridity questions
- Optional performance layer (Rcpp) if profiling proves necessary

### Icebox (explicitly not planned for v1.0 unless requested)
- Herbivore demography (birth/death)
- Soil nutrient cycling via excretion feedback
- GUI / interactive app
