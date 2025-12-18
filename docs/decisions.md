# Decisions — herbivoreTTR

This file records decisions that are hard to reverse. Each entry should include rationale and implications.

## 2025-12-16 — Public API boundary
**Decision:** The exported functions in `NAMESPACE` are treated as the public API. Internal helpers may change without notice until v1.0, but exports require deprecation discipline once released.  
**Rationale:** Users need a stable surface area; the repo already exports a coherent set of constructors and runners.  
**Implications:** Any breaking change to an exported function requires a version bump and migration notes.

## 2025-12-16 — Reproducibility stack
**Decision:** `renv` is the source of truth for dependency reproducibility; `{targets}` is the default orchestration mechanism for generating artefacts.  
**Rationale:** The repo already contains `renv.lock` and `_targets.R`, and tests rely on pipeline outputs.  
**Implications:** CI must restore via `renv` and run a targets smoke pipeline.

## 2025-12-16 — Units and conventions (authoritative)
**Decision:** Core units are explicitly documented and enforced:
- Time: minutes within day, hours for digestion queues, days for plant updates
- Herbivore mass: grams
- Plant biomass pools: kilograms dry mass (or documented equivalent)
- Energy: kJ
- Distances: meters in a toroidal plot
**Rationale:** Unit ambiguity is a primary source of silent scientific errors.  
**Implications:** Add runtime assertions and tests that guard against negative/NaN/Inf states.

## 2025-12-16 — Functional types implementation strategy
**Decision:** Grazer/browser/mixed must be behaviorally meaningful. Mixed feeders are implemented as a strategy that interpolates between graze and browse preference policies (not merely a label).  
**Rationale:** The product brief requires three functional types; mixed feeders need a definable behavior.  
**Implications:** Add tests demonstrating measurable behavioral differences across types.

## 2025-12-16 — Release and versioning policy
**Decision:** Use SemVer and Keep a Changelog. Pre-1.0 releases may change rapidly, but breaking changes must still be documented.  
**Rationale:** Scientific users need traceability across results and publications.  
**Implications:** Every release tag must correspond to a changelog entry and a reproducible artefact bundle.

## 2025-12-16 — Distribution target
**Decision:** Initial releases target GitHub-style source distribution (source tarball and artefacts). CRAN submission is not a v1.0 requirement.  
**Rationale:** The project is research-focused and may evolve quickly; CRAN constraints are heavy.  
**Implications:** CI still enforces `R CMD check --as-cran` to keep the package healthy.

## 2025-12-17 — Herbivore mass units in allometries
**Decision:** Herbivore mass is stored in state as grams, but allometric equations for energy maintenance and locomotion costs are parameterised on kilograms; these functions convert g → kg internally.  
**Rationale:** Keeps a single storage unit across the herbivore state while matching the source units used in the cited allometries.  
**Implications:** Tests and documentation must reflect the g→kg conversion; downstream users should treat `mass` as grams in the public API.

## 2025-12-17 — Digestion queue contract (MRT)
**Decision:** Gut digestion queues are fixed-length numeric vectors of length `MRT` (hours), containing finite, non-negative values; the hourly update drops the final slot and prepends a zero slot. Any `NA` values encountered in digestion queues are treated as zero during normalisation.  
**Rationale:** Prevents silent `NA` propagation and length drift, and makes domain invariants testable (gut content and daily intakes remain finite).  
**Implications:** Fixing queue mechanics can change energy/water intake trajectories versus prior buggy runs; parity fixtures and reference artefacts must be reviewed and updated with justification when they change.
