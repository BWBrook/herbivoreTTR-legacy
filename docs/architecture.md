# Architecture — herbivoreTTR

## Overview
herbivoreTTR is a coupled simulation with two interacting subsystems:

- **Plants**: a spatial grid of plants updated daily via a Thornley Transport Resistance (TTR) growth model.
- **Herbivores**: one or more individual agents that move and feed at minute resolution and track daily energy and water budgets.

A typical day:
1. Apply daily plant growth update (TTR) for all plants given environmental drivers.
2. Simulate herbivore minute-by-minute behavior (movement + intake decisions).
3. Advance digestion hourly compartments, accumulate energy intake and metabolic water.
4. Update daily energy/water balance summary.

## Core data model (state objects)

### `conditions` (environmental drivers)
A `data.frame` with at least:
- `day` (int)
- `temp_mean` (deg C)
- `sw` (standing water; units documented)
- `N` (available soil nitrogen; units documented)

### `plants` (plant grid state)
A `data.frame` with:
- Identifiers and geometry:
  - `plant_id`, `xcor`, `ycor` (toroidal environment)
  - `veg_type`, `height` (as applicable)
- Biomass pools (units documented, typically kg DM):
  - `ms`, `mr` (shoot/root mass)
  - `bleaf`, `bstem`, `bdef` (sub-pools used for herbivory + defence)
- Nutrient pools (e.g., `cs`, `cr`, `ns`, `nr`) and derived concentrations
- Daily TTR flux/resistance/derivative columns used during update

Key invariant: biomass and nutrient pools must remain finite and non-negative (within tolerance).

### `herbivore` (individual agent state)
A `list` with:
- Identity and strategy:
  - `id` (when multi-herbivore is enabled)
  - `herb_type` (0=grazer, 1=browser, 2=mixed)
  - strategy parameters (e.g., browse height constraints, preference weights)
- Spatial state:
  - `xcor`, `ycor`, `selected_plant_id`, `behaviour`
- Physiological traits:
  - `mass` (g), `gut_capacity` (g), `bite_size`, `handling_time`, `foraging_velocity`
- Digestion queues:
  - hourly vectors of ingested material and digestible carb/protein
  - initialised to a non-zero steady-state fill fraction of gut capacity (not all zeros)
- Daily trackers:
  - `intake_*`, `distance_moved`, `energy_balance`, `water_balance`, etc.

Key invariant: gut content never exceeds capacity beyond tolerance; daily intakes are non-negative; energy/water updates are finite.

## Domain sanity guards (v0)
The runner executes fail-fast domain checks at key points in `run_daily_herbivore_simulation()`:
- after daily plant growth (`phase = "post_growth"`),
- at day start after herbivore trait refresh (`phase = "start_of_day"`),
- at each simulated minute (`phase = "minute_loop"`),
- after daily water/energy bookkeeping (`phase = "end_of_day"`).

Checks enforced:
- plant core pools are finite and non-negative within tolerance (`ms`, `mr`, `bleaf`, `bstem`, `bdef`, `cs`, `cr`, `ns`, `nr`, `cd`, `nd`, `md`);
- herbivore gut constraints remain valid (`gut_capacity > 0`, `0 <= gut_content <= gut_capacity + tolerance`);
- herbivore movement and daily balances remain finite (`distance_moved`, `energy_balance`, `water_balance`);
- digestion queues are numeric, finite, and non-negative.

Error diagnostics:
- failures raise class `herbivoreTTR_domain_sanity_violation`,
- messages include the offending component plus day/minute/phase context for fast triage.

Multi-day jump guards:
- `run_herbivore_days()` enforces maximum day-to-day jumps for canonical sanity:
  - `CONSTANTS$SANITY_MAX_DAILY_ENERGY_JUMP`
  - `CONSTANTS$SANITY_MAX_DAILY_WATER_JUMP`

TTR stability guardrails:
- `transport_resistance()` enforces TTR-specific guardrails each day via `assert_ttr_guardrails()`:
  - absolute pool caps (`CONSTANTS$TTR_MAX_POOL_ABS`),
  - daily multiplicative jump cap (`CONSTANTS$TTR_MAX_DAILY_POOL_MULTIPLIER`),
  - defence fraction cap (`CONSTANTS$TTR_MAX_DEFENCE_FRACTION`),
  - defence semantics checks (`md` must mirror `bdef`; defence C/N cannot exceed shoot C/N).
- Stress verification helper:
  - `run_ttr_stress_scenario()` writes a stress artefact bundle under
    `artefacts/canonical_runs/stress_ttr_v0/` (or caller-specified location).

## Module boundaries (logical, not necessarily directory-based)

### 1) Plant subsystem (TTR)
Responsibilities:
- Compute resistances, transport, uptake, growth, and RHS derivatives.
- Apply a daily update across all plants with robust numeric guards.

Interfaces:
- `init_plants(veg_types=...) -> plants`
- `transport_resistance(plants, conditions_row, ...) -> plants` (or equivalent daily updater)

### 2) Herbivore subsystem
Responsibilities:
- Allometric trait calculation from body mass
- Candidate plant detection within range (toroidal distance)
- Plant choice using stochastic weighted sampling, where tastiness weights combine:
  - nutrient mismatch penalty (`DP:DC` target vs plant composition),
  - distance penalty,
  - defence penalty (`bdef`),
  - shoot-size bonus (`ms`) and functional-type multipliers.
- Zero-weight constraints are enforced for out-of-range, depleted, and out-of-reach browse candidates.
- Functional-type preference multipliers:
  - grazer (`herb_type = 0`): grass-upweighted, woody-downweighted
  - browser (`herb_type = 1`): woody-upweighted, grass-downweighted
  - mixed (`herb_type = 2`): explicit interpolation between grazer/browser multipliers using `mixed_browser_weight`
- Movement mechanics:
  - shortest-path toroidal motion (`herbivore_move()`) with explicit per-minute distance cap,
  - configurable target disruption probability (`movement_disruption_prob` / `MOVEMENT_DISRUPTION_PROB`) controlling retargeting frequency.
- Intake mechanics:
  - per-minute intake limit combines handling rate, gut-capacity remainder, and an optional mechanical bite cap,
  - defence fraction (`bdef / (bleaf + bstem + bdef)`) applies a multiplicative handling penalty,
  - edible removal is capped to maintain minimum standing shoot biomass (`MIN_SHOOT`) per plant.
- Digestion advancement and daily budget bookkeeping
  - `MRT` is an explicit hourly parameter with validated bounds; queue resizing preserves queued mass totals

Interfaces:
- `init_herbivore(mass, herb_type, MRT, ...) -> herbivore`
- `herbivore_step(herbivore, plants) -> list(herbivore, plants)`
- `hourly_digestion_step(herbivore) -> herbivore`
- `calc_daily_energy_balance(herbivore) -> herbivore`
- `check_daily_water_balance(herbivore, ...) -> herbivore`

### 3) Simulation orchestration
Responsibilities:
- Couple plant daily update and herbivore within-day loop
- Multi-day wrapper
- Optional diagnostics logging

Interfaces:
- `run_daily_herbivore_simulation(herbivore, plants, conditions, day_of_simulation, minute_limit, ...)`
- `run_herbivore_days(days, minute_limit, ...)`
- `run_functional_type_scenario(minute_limit, seed, ...)` (controlled grazer/browser artefact helper)

For Beta:
- `run_daily_simulation_population(herbivores, plants, conditions, ...)`
- Deterministic update ordering rules (documented)

### 4) IO and artefacts
Responsibilities:
- Write stable-schema snapshots and logs
- Version output schemas and document column meanings

Interfaces:
- `write_*_snapshot_*()` helpers (targets-friendly)
- `summarise_hourly_herbivore_record()` and `write_hourly_herbivore_log()`

### 5) Reproducibility workflows
- `{targets}` is the canonical pipeline for repeatable runs and artefact generation.
- `renv` locks dependencies for reproducibility and CI parity.

## Determinism rules
- A fixed seed must reproduce:
  - random choices (plant selection, movement randomness if any)
  - pipeline outputs (CSV snapshots)
- Floating point tolerance rules must be explicitly documented for any approximate comparisons.

## Parameter and units reference
- Authoritative parameter metadata is maintained by:
  - `parameter_reference_table()`
  - `units_conventions_table()`
  - `canonical_smoke_parameters()`
- User-facing reference documentation is maintained in `docs/parameter_units_reference.md`.

## Extension points
- New herbivore types: implement as strategy parameters plus a documented “selection + bite allocation” policy.
- New climate drivers: extend `conditions` schema and plant update function(s).
- New output products: add targets that consume stable-schema snapshots rather than ad hoc side effects.

## Performance notes (design intent)
- Keep hot loops (minute-resolution stepping) free of heavy tidyverse transforms.
- Prefer precomputed vectors and base R operations in the inner loop.
- Profile before optimizing; avoid premature refactors that change scientific meaning.
