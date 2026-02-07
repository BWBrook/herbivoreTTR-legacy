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

## 2026-02-06 — Cross-platform CI support policy
**Decision:** The supported CI posture is Linux + macOS + Windows for package check/installability, with Linux remaining the full gate runner for tests/lint/targets smoke/coverage in this phase.  
**Rationale:** Publication-oriented reproducibility benefits from explicit multi-OS installation and check coverage, while keeping heavy validation jobs focused on a single deterministic runtime for speed and maintainability.  
**Implications:** CI matrices must include all three OSes for `R CMD check`; Linux-only gate jobs remain mandatory blockers until the roadmap promotes broader full-gate matrices.

## 2026-02-06 — Output contract v0 schema discipline
**Decision:** Canonical smoke outputs use `schema_version = "0.1.0"` with required CSV schemas (`plants_day*.csv`, `herb_day*.csv`) and a required `run_manifest.json` under `artefacts/canonical_runs/smoke_v0/`.  
**Rationale:** Stable, interpretable artefacts are required for regression testing and publication evidence packs.  
**Implications:** Any incompatible output column or manifest change requires a schema version bump, migration notes, and regression test updates.

## 2026-02-06 — Determinism contract for seeded runs
**Decision:** Exported runners (`run_daily_herbivore_simulation()`, `run_herbivore_days()`) accept optional `seed` and execute with local RNG scoping that restores caller RNG state after return. Canonical determinism is strict equality on same OS/runtime; cross-OS numeric drift policy defaults to tolerance `1e-10` when approximate comparison is needed.  
**Rationale:** Deterministic seeded runs are required for reproducible smoke artefacts and trustworthy regression tests without contaminating external RNG workflows.  
**Implications:** Determinism tests must include seeded repeatability and RNG restoration behavior; canonical artefact comparisons should ignore only explicit volatile fields (for example manifest timestamp).

## 2026-02-06 — Domain sanity fail-fast policy (v0)
**Decision:** The simulation runners enforce explicit runtime domain checks and abort with contextual diagnostics when violated. The v0 checks cover finite/non-negative plant pools, gut-capacity constraints, finite energy/water balances, and finite/non-negative digestion queues. Multi-day summaries additionally enforce bounded day-to-day jumps using `SANITY_MAX_DAILY_ENERGY_JUMP` and `SANITY_MAX_DAILY_WATER_JUMP`.  
**Rationale:** Silent non-physical state drift undermines scientific trust. Fast, contextual failure is preferable to producing artefacts that look valid but encode invalid states.  
**Implications:** Runs may now fail earlier when invalid states appear; failures will include offending component plus day/minute/phase and should be treated as model defects (not ignored as numerical noise).

## 2026-02-06 — Parameter reference source of truth and nutrient-target wording
**Decision:** Parameter/units reference metadata is centralized in code via `parameter_reference_table()`, `units_conventions_table()`, and `canonical_smoke_parameters()`, and documented in `docs/parameter_units_reference.md`. Nutrient-target wording explicitly distinguishes reporting target (`NPE_TO_PE_TARGET`) from the current foraging proxy target (`DP_TO_DC_TARGET`).  
**Rationale:** WP-0.3.8 requires a single authoritative reference that cannot silently drift from defaults used by canonical runs. Separating reporting vs proxy targets reduces ambiguity in interpretation and manuscript wording.  
**Implications:** Tests must enforce sync between reference tables, constants, and canonical scenario defaults; future target-policy changes must update both code metadata and this decision record.

## 2026-02-06 — TTR defence pool semantics and stability caps (v0)
**Decision:** Structural defence biomass is represented by a single authoritative mass pool (`bdef`) that is mirrored to `md` each TTR day. When defence transport dynamics are disabled (`DEFENCE_ENABLED = 0`), `cd` and `nd` are held at zero. TTR updates enforce explicit stability caps:
- absolute per-plant pool cap (`TTR_MAX_POOL_ABS`),
- maximum one-day multiplicative jump (`TTR_MAX_DAILY_POOL_MULTIPLIER`),
- maximum defence fraction of shoot mass (`TTR_MAX_DEFENCE_FRACTION`),
- chemistry consistency (`cd <= cs`, `nd <= ns`).
  
**Rationale:** Prior instability risks included runaway pool growth and drift between duplicated defence mass representations (`bdef` vs `md`). A single defence mass semantic plus explicit numeric caps prevents silent divergence while retaining fail-fast diagnostics when behaviour leaves documented bounds.  
**Implications:** TTR updates now fail fast on guardrail violations with contextual diagnostics; stress scenario artefacts and tests are required to confirm stability under documented stress inputs.

## 2026-02-06 — Functional-type foraging split policy (v0.4.1)
**Decision:** Grazer/browser distinction is enforced in tastiness scoring with explicit vegetation-type multipliers:
- grazer (`herb_type = 0`): `GRAZER_GRASS_PREF > 1`, `GRAZER_WOODY_PREF < 1`;
- browser (`herb_type = 1`): `BROWSER_WOODY_PREF > 1`, `BROWSER_GRASS_PREF < 1`.
Browser browse-height gating remains enforced by `get_plants_within_range()`.

**Rationale:** WP-0.4.1 requires measurable and reproducible diet-composition divergence in a controlled grass + tree scenario; browse-height filtering alone did not provide a robust ecological split.

**Implications:** Functional-type behaviour is now auditable via `run_functional_type_scenario()` artefacts and regression tests that assert directional diet differences and zero browser intake from unreachable woody plants.

## 2026-02-06 — Mixed-feeder interpolation policy (v0.4.2)
**Decision:** Mixed feeders (`herb_type = 2`) are implemented as an explicit interpolation between grazer and browser tastiness multipliers with parameter `MIXED_BROWSER_WEIGHT` (`0 = grazer policy`, `1 = browser policy`). Mixed feeders share browse-height reach constraints with browsers.

**Rationale:** WP-0.4.2 requires mixed feeders to be a measurable strategy, not a label. A convex interpolation keeps behavior interpretable, tunable, and testable against directional intermediate outcomes.

**Implications:** Controlled three-way scenario artefacts (`grazer`, `browser`, `mixed`) and regression tests now enforce that mixed diet composition is distinct and directionally intermediate under fixed seed.

## 2026-02-06 — Plant selection stochastic-weight contract (v0.4.3)
**Decision:** Plant selection is formally defined as weighted stochastic sampling where each candidate plant receives a non-negative tastiness weight:
- `weight = functional_multiplier * size_bonus / (epsilon + w_ratio * nutrient_mismatch + w_distance * distance + w_defence * defence)`
- candidates violating hard constraints receive zero weight:
  - `distance > DETECTION_DISTANCE`,
  - `ms <= MIN_SHOOT`,
  - for browser/mixed: `LEAF_HEIGHT * height > BROWSE_HEIGHT` (when `height` exists).

Constants introduced:
- `TASTINESS_RATIO_WEIGHT`
- `TASTINESS_DISTANCE_WEIGHT`
- `TASTINESS_DEFENCE_WEIGHT`
- `TASTINESS_EPSILON`

**Rationale:** WP-0.4.3 requires that selection factors and direction of effects are explicit and testable, while preserving stochastic choice behavior (not always selecting the single best plant).

**Implications:** Selection behavior is now auditable through controlled artefacts (`selection_contract_v0`) and acceptance tests that enforce zero-probability constraints, directional defence/distance effects, and fixed-seed determinism.

## 2026-02-06 — Movement contract with explicit disruption probability (v0.4.4)
**Decision:** Herbivore movement follows explicit toroidal shortest-path geometry through a single movement primitive (`herbivore_move()`), and target disruption is parameterised by `MOVEMENT_DISRUPTION_PROB` (per-step probability, clamped to `[0, 1]` via `movement_disruption_prob` in herbivore state).

Operational policy:
- while moving, herbivores retain their current valid target unless a disruption draw succeeds;
- if disrupted or target invalid, a new target is selected stochastically;
- movement per minute is capped at `fv_max * 60` and wrapped on a torus.

**Rationale:** WP-0.4.4 requires interpretable edge-wrapping movement and a configurable mechanism that controls retargeting frequency.

**Implications:** Movement and retargeting behavior are now testable against explicit contracts (wrap correctness, step cap, disruption effect) and auditable via `movement_contract_v0` artefacts.

## 2026-02-06 — Foraging-rate contract uses defence-adjusted handling and component-based residual floor (v0.4.5)
**Decision:** Minute-level intake in `herbivore_eat()` is constrained by the minimum of:
- defence-adjusted handling limit,
- gut-capacity remainder,
- mechanical cap,
- available shoot above `MIN_SHOOT`.

The available-shoot limit is computed from component pools (`bleaf + bstem + bdef`) rather than the aggregate `ms` field so component/aggregate drift cannot allow over-removal. Daily defence intake (`intake_defence_day`) is explicitly tracked.

**Rationale:** WP-0.4.5 requires measurable defence handling penalties and an enforced minimum residual biomass rule. Computing availability from component pools makes the residual-floor contract robust even if `ms` and component pools diverge.

**Implications:** Defence effects on intake rate and residual-floor behavior are now contract-tested and auditable through `foraging_contract_v0` artefacts.

## 2026-02-06 — Digestion model v1 policy: explicit MRT bounds + steady-state queue initialisation (v0.4.6)
**Decision:** Digestion queues are initialised with a non-zero steady-state fill assumption instead of all-zero vectors. `MRT` remains an explicit user-facing parameter, defaults to `CONSTANTS$HERBIVORE_MRT` (24 h), and is validated within `[MRT_MIN_HOURS, MRT_MAX_HOURS]` (currently `[1, 72]`). Queue resizing for MRT changes preserves queued mass totals by redistribution rather than dropping to zero.

Operational contract:
- initial seeded gut biomass = `gut_capacity * DIGESTION_INIT_FILL_FRACTION`,
- seeded biomass is split across `bleaf`, `bstem`, `bdef` using digestion init fractions,
- digestible queues are seeded from biomass queues using the same carb/protein conversion factors used during intake scheduling,
- hourly digestion remains a strict queue shift where terminal slot material is released to daily intake counters and metabolic-water accounting.

**Rationale:** WP-0.4.6 requires biologically plausible day-1 digestion dynamics and robustness for large herbivores. Zero-initialisation combined with long retention windows can produce artificial early-day starvation signals that are modelling artefacts, not ecology.

**Implications:** Canonical day-1 herbivore energy outputs change relative to zero-initialisation fixtures; parity fixtures and interpretation notes must be refreshed with rationale. Digestion contract artefacts (`digestion_contract_v1`) and dedicated tests now guard queue invariants, MRT sensitivity, and plausible release timing.

## 2026-02-06 — Water balance v1 policy: forage-water uptake + explicit daily water terms + drinking distance penalty (v0.4.7)
**Decision:** Water accounting is promoted to an explicit daily contract:
- forage water is accrued during `herbivore_eat()` from plant shoot water (`qshoot`) in proportion to consumed shoot dry matter and deducted from `qshoot`,
- daily water closure uses explicit terms (`daily_water_requirement`, `intake_water_forage`, `metabolic_water_day`, `intake_water_drinking`),
- daily net water balance is tracked as `daily_net_water_balance = metabolic + forage + drinking - requirement`,
- drinking deficit closure increases daily distance by `DIST_TO_WATER`, so energetic drinking cost is represented via locomotion energy.

**Rationale:** WP-0.4.7 requires water balance to be observable, testable, and behaviour-coupled. Prior implementation tracked fields but did not wire forage-water uptake in feeding, leaving water dynamics under-specified.

**Implications:** Canonical day outputs may change where forage-water uptake alters drinking requirements and thus movement/energy costs. Water contract artefacts (`water_contract_v1`) and dedicated tests now guard trigger behavior, energetic penalty semantics, and finite/consistent water bookkeeping.

## 2026-02-06 — Foraging objective mode toggle for novelty contrast (v0.4.8)
**Decision:** Add an explicit herbivore-level `foraging_mode` toggle with two valid values:
- `nutrient_targeting` (default): include DP:DC mismatch in tastiness and persistence probability,
- `energy_only`: disable nutrient mismatch weighting while keeping distance, defence, size, and functional-type terms unchanged.

Operational contract:
- mode resolution is strict with fallback to `nutrient_targeting` for missing/invalid values,
- paired day-in-life comparison runs must use identical seeds and initial conditions, differing only by `foraging_mode`,
- acceptance is based on measurable divergence in at least one pre-defined intake/selection metric.

**Rationale:** WP-0.4.8 requires a reproducible novelty demonstration, isolating the effect of nutrient targeting from other behavioural mechanisms.

**Implications:** New canonical artefacts (`day_in_life_nutrient_targeting_v1`, `day_in_life_energy_only_v1`, and `day_in_life_mode_comparison_v1`) and tests now guard the mode-difference claim.

## 2026-02-06 — Scenario contract v1 as canonical run entry (WP-0.5.1)
**Decision:** Experiments are configured through scenario contract v1 (`schema_version = "1.0.0"`) with YAML front-end compilation and strict validation. `config/scenarios/*.yaml` is source-of-truth in checkout, with installed fallback copies under `inst/extdata/scenarios/`.  
**Rationale:** A stable scenario boundary is required for reproducible experiments, targets integration, and deterministic regression testing.  
**Implications:** New canonical/reference runs must originate from validated scenarios; invalid scenario fields fail fast with structured error classes.

## 2026-02-06 — Output schema v1 migration with run/cohort identifiers (WP-0.5.2)
**Decision:** Output schema is bumped to `1.0.0` and now requires `RunID` (all output tables), `HerbivoreID` (herbivore outputs), and manifest field `run_id`. v0 (`0.1.0`) remains migration-input only via explicit migration helpers.  
**Rationale:** Cohort-ready and scenario-traceable outputs require explicit identifiers to avoid ambiguous merges/joins in downstream analyses.  
**Implications:** Canonical fixtures moved to v1; migration notes/tests are mandatory for any further incompatible output changes.

## 2026-02-06 — Deterministic cohort ordering policy (WP-0.5.3, WP-0.5.4)
**Decision:** Multi-herbivore within-day updates execute in lexical `herbivore_id` order after one daily plant growth step. Plant state is shared and updated sequentially across herbivores in that order.  
**Rationale:** Explicit ordering removes hidden nondeterminism and makes coupling semantics auditable.  
**Implications:** Cohort scenarios must use unique IDs; changing ordering semantics is a behavior change requiring decision/log updates and regression review.

## 2026-02-06 — Implicit stocking-density semantics (WP-0.5.5)
**Decision:** Implicit mode converts stocking density to effective daily representative visits:
`effective_visits = stocking_density_per_km2 * plot_area_km2 * visitation_rate_per_day`.
Full and fractional visits are executed deterministically; outputs are explicitly labeled `implicit_representative` and record visitation parameters.  
**Rationale:** Supports macroecological pressure questions without simulating large explicit cohorts while preserving interpretable mechanics.  
**Implications:** Implicit outputs are not interchangeable with explicit cohorts without mode-aware interpretation.

## 2026-02-06 — Performance budget gate for CI-profile scenario (WP-0.5.6)
**Decision:** A mandatory small-scenario runtime gate is set at `< 30s` for CI-profile checks (`test_performance_budget_v1.R`), with profiling artefact reports recorded under `artefacts/canonical_runs/performance_budget_v1/`.  
**Rationale:** Prevents major runtime regressions while avoiding brittle micro-optimisation thresholds.  
**Implications:** Performance regressions now fail tests; hotspot changes must retain scientific behavior and update profiling notes.

## 2026-02-06 — Plant backend interface boundary (WP-0.5.7)
**Decision:** Plant updates are abstracted through backend interface members: `init`, `step_day`, `apply_herbivory`, `observe`, with `internal_ttr` as default backend.  
**Rationale:** Decouples herbivore orchestration from plant backend implementation and enables optional benchmarking adapters.  
**Implications:** Backend swaps must preserve documented interface behavior; default internal backend remains behavior-preserving baseline.

## 2026-02-06 — TTR.PGM remains benchmark-only optional harness (WP-0.5.8)
**Decision:** `TTR.PGM` integration is optional and benchmark-oriented only; default coupled runs remain on internal multi-PFT backend. Conditional benchmark artefacts/tests are provided without making package installation mandatory.  
**Rationale:** Current overlap is useful for credibility checks, but internal backend is required for coupled multi-PFT workflows.  
**Implications:** CI must stay green without `TTR.PGM`; benchmark divergences or adapter limitations are documented explicitly (not silently ignored).

## 2026-02-06 — Structure/fuel derived metric contract (WP-0.6.1)
**Decision:** Canonical scenario outputs include stable derived vegetation structure/fuel metrics (`total_shoot_biomass_kg`, `fine_fuel_proxy_kg`, `browseable_biomass_kg`, etc.) in `structure_fuel_daily.csv`.  
**Rationale:** Fuel/structure questions should be answerable directly from outputs without reverse-engineering raw pools.  
**Implications:** New experiments/reports must consume documented derived metrics; schema changes require contract update + tests.

## 2026-02-06 — Reference scenario library as scientific narrative backbone (WP-0.6.2)
**Decision:** A curated scenario library (presence/removal + grazer/browser/mixed) is maintained as explicit YAML definitions with expected qualitative outcomes and indexed artefacts.  
**Rationale:** Encodes the paper storyline in reproducible scenarios, reducing ad hoc experiment drift.  
**Implications:** Scenario purpose/expectation docs and artefact index must be kept in sync with scenario files.

## 2026-02-06 — Paper experiments are artefact-first and report-backed (WP-0.6.3 to WP-0.6.6)
**Decision:** Experiments A/B/C and benchmark appendix are generated by reproducible helper functions that write summary tables, plots, short interpretation reports, and manifests in canonical artefact folders.  
**Rationale:** Makes interpretation auditable and publication-ready without manual notebook state.  
**Implications:** Experiment claims must be tied to generated tables/plots and logged sanity notes.

## 2026-02-06 — Paper pipeline renders from artefacts, not reruns (WP-0.6.7)
**Decision:** Quarto skeleton (`reports/paper_pipeline.qmd`) reads prebuilt artefacts under `artefacts/canonical_runs/` and renders to `artefacts/reports/` via `render_paper_pipeline_report()`.  
**Rationale:** Separates expensive simulation generation from narrative rendering and preserves reproducible report builds.  
**Implications:** Pipeline target dependencies must ensure experiment artefacts exist before report render.

## 2026-02-06 — API freeze v1 with scenario-first public entrypoints (WP-1.0.1)
**Decision:** The v1 public API is frozen and documented in `docs/api_surface_v1.md`, with scenario contract entrypoints as the primary user-facing surface and legacy state-level exports retained as supported advanced APIs.  
**Rationale:** Users need a stable, publication-citable interface while preserving backward-compatible access to lower-level workflows already used in tests and scripts.  
**Implications:** Changes to exported function names or argument semantics now require deprecation-policy handling and changelog migration notes.

## 2026-02-06 — Deprecation policy is mandatory for API/schema changes (WP-1.0.1)
**Decision:** `docs/deprecation_policy.md` is now normative for exported functions and schema contracts.  
**Rationale:** v1 stabilisation requires explicit compatibility guarantees to avoid accidental breaking changes during publication-facing use.  
**Implications:** Future removals or breaking behavior changes must follow the documented soft/hard/removal cycle unless an explicitly logged correctness exception applies.

## 2026-02-06 — Release candidates are folder bundles, not ZIP artefacts (WP-1.0.2/WP-1.0.4)
**Decision:** Release candidate evidence is assembled under `artefacts/release_candidates/<release_label>/` with manifest + checklist files, rather than packaging a dedicated PI ZIP.  
**Rationale:** Maintainer protocol now prefers autonomous in-repo release bundles over manual ZIP packaging while preserving complete traceability.  
**Implications:** Roadmap/release checks treat the release-candidate folder as the sign-off artefact; no standalone ZIP is required.

## 2026-02-06 — External reproducibility verification uses isolated renv library runs (WP-1.0.3)
**Decision:** External reproducibility is verified by restoring dependencies into an isolated `RENV_PATHS_LIBRARY`, running CI-profile targets, and writing evidence logs/manifests under `artefacts/reproducibility/external_run_v1/`.  
**Rationale:** This approximates a third-party clean environment without requiring bespoke container infrastructure for every local validation pass.  
**Implications:** `make repro-check` becomes a release gate input, and failures are actionable via step-specific logs.

## 2026-02-06 — Package version advanced to 1.0.0 for release-candidate gating (WP-1.0.2)
**Decision:** `DESCRIPTION` version is now `1.0.0`, with matching changelog header and release artefact pipeline records.  
**Rationale:** Release checklist SemVer requirements and API-freeze posture require an explicit v1 version anchor rather than a development-only `0.0.0.9000` marker.  
**Implications:** Subsequent changes post-RC should increment version according to SemVer and deprecation policy.

## 2026-02-07 — Scenario-level RNG determinism is mandatory for full run execution (WP-2.4 reproducibility hardening)
**Decision:** `run_scenario_v1()` now executes within a scenario-seeded RNG scope (`with_optional_seed(validated$runtime$seed, ...)`) so stochastic initial state construction (`init_plants()`, herbivore initial coordinates, and any downstream random draws outside per-day local seeds) is deterministic and does not depend on caller RNG history.  
**Rationale:** External v2 reproducibility failed intermittently when long-horizon stability suites inherited different RNG states from earlier runs in the same R session. This caused occasional domain-sanity violations under identical scenario configs.  
**Implications:** Fixed-seed scenario runs are now reproducible across invocation order; parity fixtures and canonical day-1 snapshots were refreshed to the new deterministic baseline.

## 2026-02-07 — Experiment A v2 claim policy distinguishes required integrity checks from optional directional ecology claims (WP-2.1.4)
**Decision:** Claim gating for Experiment A v2 uses a minimal required claim (`n_replicates >= 1`) plus optional directional/support-share claims (`required = FALSE`) recorded as supported/not_supported in report tables.  
**Rationale:** Directional biomass/fuel claims can be violated at small ensemble sizes without indicating a broken pipeline. Blocking on those claims produced false gate failures that obscured execution integrity checks.  
**Implications:** Report consumers must treat directional claim rows as interpretive evidence, not hard run validity; required claims remain strict release-gate criteria.

## 2026-02-07 — Tiered CI is the default v1.1 operating model (WP-2.4.3)
**Decision:** CI responsibilities are split into:
- lean blocking PR checks (`check` + `test` + `lint` + smoke targets),
- nightly deep ecological suites,
- weekly clean-library reproducibility runs.
  
**Rationale:** This keeps day-to-day development fast while preserving regular deep scientific and reproducibility audits.  
**Implications:** PR failures are immediate blockers; nightly/weekly failures must be logged and triaged with explicit remediation steps in `docs/log/`.

## 2026-02-07 — Across-run parallel execution defaults for ensembles and stability suites (WP-2.6.1)
**Decision:** Multi-run workloads now share an explicit execution-mode contract (`execution_mode = auto|serial|multicore`) with deterministic output ordering guarantees. In `auto`, runs default to serial on CI and multicore on local hosts (bounded by available cores and `reserve_cores`).  
**Rationale:** The model is CPU-bound at the replicate/scenario level, and process-level parallelism provides a strong throughput opportunity without changing within-run ecological mechanics. A unified execution plan keeps behavior reproducible and auditable.  
**Implications:** Ensemble/stability artefacts now include execution metadata in manifests. Serial and multicore runs with identical seeds must remain numerically equivalent in summaries; this is regression-tested.

## 2026-02-07 — Break-even benchmarking policy for parallel overhead (WP-2.6.3)
**Decision:** `run_post_v1_scaling_profile()` now emits a serial-vs-parallel benchmark matrix and break-even summary (`parallel_overhead_benchmark_v1.csv`, `parallel_break_even_summary_v1.csv`) plus an optional break-even gate. The gate is non-blocking by default (`enforce_break_even_gate = FALSE`) unless explicitly enabled on controlled hardware.  
**Rationale:** Hardware-dependent overhead can invert expected speedups for small replicate counts; policy decisions should be based on measured break-even curves rather than assumptions. Default non-blocking behavior preserves CI stability while still surfacing performance drift evidence.  
**Implications:** Performance tuning should consult break-even artefacts before changing default worker policies. If strict break-even gating is desired, projects must set explicit thresholds and runner assumptions.

## 2026-02-07 — Ecologist portal contract uses YAML as the primary non-coder control surface (WP-3.1.1 to WP-3.1.7)
**Decision:** Non-coder execution is standardized around a versioned portal plan schema (`schema_version = "1.0.0"`) with one YAML file defining scenario source, overrides, sensitivity design, output/report options, and execution controls. CLI scripts and the GUI stub both route through the same backend runner (`run_portal_plan_v1()`).  
**Rationale:** The target audience includes ecologists who prefer declarative experiment setup over direct R coding. A single source-of-truth plan file lowers entry friction while preserving reproducibility and auditability.  
**Implications:** Backward-incompatible portal plan changes require schema version bumps and migration notes. User-facing onboarding should continue to prioritize YAML templates and command-line calls.

## 2026-02-07 — Portal reporting defaults to HTML; PDF is optional best-effort (WP-3.1.5)
**Decision:** Portal report rendering always targets requested formats explicitly and defaults to HTML-only unless PDF is requested. PDF rendering is treated as optional and non-failing, with outcomes logged to `reports/report_render_notes.md`.  
**Rationale:** Requiring PDF toolchains for all users creates avoidable platform friction for non-coder workflows. HTML provides a robust baseline output for local inspection and sharing.  
**Implications:** CI and local validation should treat HTML report generation as the required report artefact. Missing PDF output is informational unless explicitly configured as a project-level requirement.
