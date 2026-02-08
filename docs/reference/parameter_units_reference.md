# Parameter & Units Reference (WP-0.3.8)

This is the authoritative reference for herbivore allometries, core model defaults, and units conventions used in canonical runs.

Code source of truth:
- `R/constants.R`
- `R/parameter_reference.R` (`parameter_reference_table()`, `units_conventions_table()`, `canonical_smoke_parameters()`)

## Units conventions

The following conventions are mandatory for interpreting inputs/outputs:

| Quantity | Unit | Notes |
|---|---|---|
| Herbivore body mass | g | Stored in grams; allometric equations convert internally to kg where required. |
| Plant biomass pools | kg dry mass | Includes `ms`, `mr`, `bleaf`, `bstem`, `bdef`, `md`. |
| Plant C/N pools | kg C or kg N | Includes `cs`, `cr`, `ns`, `nr`, `cd`, `nd`. |
| Energy | kJ | Daily balances and maintenance/locomotion costs use kJ. |
| Water | g water equivalent | Water requirement and balances are tracked in gram-equivalent units. |
| Distance | m | Toroidal movement and water travel penalties are in meters. |
| Time (plant update) | day | TTR growth and transport are updated once per day. |
| Time (herbivore loop) | minute | Movement/foraging decisions occur each simulated minute. |
| Time (digestion queues) | hour | Digestion vectors shift once per simulated hour. |

## Herbivore allometries and key constants

Equation form:
- `trait = A * mass_kg^B` for allometric traits.

Mass convention:
- Public herbivore state stores `mass` in grams.
- Allometric functions convert `mass_g / 1000` to kilograms before applying formulas.

Key parameters (from `parameter_reference_table()`):

| Parameter | Value | Units | Description | Citation / source |
|---|---:|---|---|---|
| `GUT_CAPACITY_A` | `0.03` | kg DM / kg body mass^B | Gut capacity allometry coefficient | Muller et al. (2013) Table 6 |
| `GUT_CAPACITY_B` | `0.924` | unitless | Gut capacity allometry exponent | Muller et al. (2013) Table 6 |
| `BITE_SIZE_A` | `0.096` | g DM / bite / kg body mass^B | Bite size allometry coefficient | Shipley et al. (1994) |
| `BITE_SIZE_B` | `0.72` | unitless | Bite size allometry exponent | Shipley et al. (1994) |
| `HANDLING_TIME_A` | `1.65` | min / g DM / kg body mass^B | Handling time allometry coefficient | Jeschke and Tollrian (2005) |
| `HANDLING_TIME_B` | `-0.766` | unitless | Handling time allometry exponent | Jeschke and Tollrian (2005) |
| `FORAGE_VEL_A` | `0.73` | m / s / kg body mass^B | Foraging velocity allometry coefficient | Shipley et al. (1996) |
| `FORAGE_VEL_B` | `0.04` | unitless | Foraging velocity allometry exponent | Shipley et al. (1996) |
| `ENERGY_MAINTENANCE_A` | `293` | kJ / day / kg body mass^B | Maintenance cost allometry coefficient | Kleiber (1961) |
| `ENERGY_MAINTENANCE_B` | `0.75` | unitless | Maintenance cost allometry exponent | Kleiber (1961) |
| `ICL_A` | `10678` | J / m / kg body mass^B | Locomotion cost allometry coefficient | Taylor et al. (1980) |
| `ICL_B` | `0.7` | unitless | Locomotion cost allometry exponent | Taylor et al. (1980) |
| `WATER_TURNOVER` | `0.088` | L / kg body mass / day | Daily water turnover coefficient | McFarlane (1965) |
| `DIST_TO_WATER` | `100` | m / day | Distance travelled to drink when deficit occurs | Model assumption (v0) |
| `HERBIVORE_MRT` | `24` | hour | Default mean retention time used for canonical herbivore initialisation | Digestion policy (v0.4.6) |
| `MRT_MIN_HOURS` | `1` | hour | Minimum allowed explicit MRT parameter | Digestion policy guardrail (v0.4.6) |
| `MRT_MAX_HOURS` | `72` | hour | Maximum allowed explicit MRT parameter | Digestion policy guardrail (v0.4.6) |
| `DIGESTION_INIT_FILL_FRACTION` | `0.35` | unitless fraction | Initial gut-fill fraction used to seed digestion queues | Digestion initialisation policy (v0.4.6) |
| `DIGESTION_INIT_LEAF_FRACTION` | `0.7` | unitless fraction | Seeded gut biomass share allocated to leaf pool | Digestion initialisation policy (v0.4.6) |
| `DIGESTION_INIT_STEM_FRACTION` | `0.25` | unitless fraction | Seeded gut biomass share allocated to stem pool | Digestion initialisation policy (v0.4.6) |
| `DIGESTION_INIT_DEFENCE_FRACTION` | `0.05` | unitless fraction | Seeded gut biomass share allocated to defence pool | Digestion initialisation policy (v0.4.6) |
| `NPE_TO_PE_TARGET` | `4.55` | unitless ratio | Daily target ratio for non-protein:protein energy | Model target definition (v0) |
| `DP_TO_DC_TARGET` | `0.2` | unitless ratio | Daily target ratio for digestible protein:digestible carbohydrate | Model target proxy definition (v0) |
| `MIN_SHOOT` | `0.001` | kg DM | Minimum shoot biomass left for plant persistence | Model assumption (v0) |
| `BROWSE_HEIGHT` | `2` | m | Maximum browse height for browser/mixed access | Model assumption (v0) |
| `GRAZER_GRASS_PREF` | `1.5` | unitless | Grazer tastiness multiplier for grass plants (`veg_type` 0/1) | Functional-type policy (v0.4.1) |
| `GRAZER_WOODY_PREF` | `0.5` | unitless | Grazer tastiness multiplier for woody plants (`veg_type` 2) | Functional-type policy (v0.4.1) |
| `BROWSER_GRASS_PREF` | `0.5` | unitless | Browser tastiness multiplier for grass plants (`veg_type` 0/1) | Functional-type policy (v0.4.1) |
| `BROWSER_WOODY_PREF` | `1.5` | unitless | Browser tastiness multiplier for woody plants (`veg_type` 2) | Functional-type policy (v0.4.1) |
| `MIXED_BROWSER_WEIGHT` | `0.5` | unitless | Mixed-feeder interpolation weight (`0=grazer`, `1=browser`) | Mixed-feeder policy (v0.4.2) |
| `TASTINESS_RATIO_WEIGHT` | `1` | unitless | Weight for nutrient-mismatch penalty in plant-selection denominator | Plant-selection contract (v0.4.3) |
| `TASTINESS_DISTANCE_WEIGHT` | `1` | unitless | Weight for distance penalty in plant-selection denominator | Plant-selection contract (v0.4.3) |
| `TASTINESS_DEFENCE_WEIGHT` | `1` | unitless | Weight for defence (`bdef`) penalty in plant-selection denominator | Plant-selection contract (v0.4.3) |
| `TASTINESS_EPSILON` | `1e-6` | unitless | Numeric floor added to selection denominator | Plant-selection contract (v0.4.3) |
| `MOVEMENT_DISRUPTION_PROB` | `0.1` | unitless probability | Per-step probability of dropping current target while moving | Movement contract (v0.4.4) |
| `SANITY_MAX_DAILY_ENERGY_JUMP` | `100000` | kJ / day | Max tolerated day-to-day energy jump guardrail | Domain sanity policy (v0) |
| `SANITY_MAX_DAILY_WATER_JUMP` | `50000` | water units / day | Max tolerated day-to-day water jump guardrail | Domain sanity policy (v0) |

## TTR stability controls (WP-0.3.9)

Additional guardrail constants used by `assert_ttr_guardrails()`:

| Parameter | Value | Units | Description |
|---|---:|---|---|
| `TTR_MAX_POOL_ABS` | `10000` | pool units | Absolute per-plant cap for TTR pools (`ms`, `mr`, `cs`, `cr`, `ns`, `nr`, `bdef`, `md`, `cd`, `nd`). |
| `TTR_MAX_DAILY_POOL_MULTIPLIER` | `5` | unitless | Maximum tolerated one-day multiplicative jump in key pools (`ms`, `mr`, `cs`, `cr`, `ns`, `nr`, `bdef`). |
| `TTR_MAX_DEFENCE_FRACTION` | `0.35` | unitless | Maximum allowed defence biomass fraction (`bdef / ms`). |
| `TTR_DEFENCE_ALLOCATION_PROP` | `0.0001` | unitless | Default share of shoot growth routed into structural defence biomass. |

## Canonical smoke defaults

Canonical smoke defaults are now authored as scenario YAML:
- `config/scenarios/canonical_smoke_v1.yaml`

`canonical_smoke_parameters()` is a compatibility helper that compiles that
scenario and returns canonical runtime/parameter fields consumed by `_targets.R`
as `canonical_scenario_parameters`.

Current canonical defaults:
- `temp_mode = "flat"`
- `veg_types = c(0, 1, 2)`
- `herbivore_mass = 5e5` (g)
- `herb_type = 0`
- `herbivore_mrt = 24`
- `herbivore_foraging_mode = "nutrient_targeting"`
- `minute_limit = 60`
- `start_day = 1826`
- `days = 7`
- `seed = 1`

## Nutrient target meaning in code terms

Two related target ratios are present:
- `NPE_TO_PE_TARGET`: ratio of daily non-protein to protein energy intake target.
- `DP_TO_DC_TARGET`: digestible-protein to digestible-carbohydrate target proxy used in plant tastiness/selection logic.

Current interpretation:
- Foraging heuristics are currently implemented around `DP_TO_DC_TARGET` in decision scoring.
- Energy accounting records `DailyNPEI` and `DailyPEI` for reporting and downstream interpretation.

## Functional-type selection policy (WP-0.4.1)

Current v0.4.1 behavior in `calc_plant_tastiness()`:
- Grazers (`herb_type = 0`) up-weight grasses and down-weight woody plants.
- Browsers (`herb_type = 1`) up-weight woody plants and down-weight grasses.
- Browser and mixed-feeder reach constraints apply via `get_plants_within_range()` and `BROWSE_HEIGHT`.
- Mixed feeders (`herb_type = 2`) use explicit interpolation between grazer and browser preference multipliers, controlled by `MIXED_BROWSER_WEIGHT`.

The controlled scenario helper `run_functional_type_scenario()` writes reproducible diet-split artefacts under:
- `artefacts/canonical_runs/functional_types_v0/`

## Plant-selection scoring contract (WP-0.4.3)

Current v0.4.3 behavior in `calc_plant_tastiness()`:
- Candidate score is computed as:
  - `score = functional_multiplier * size_bonus / (TASTINESS_EPSILON + TASTINESS_RATIO_WEIGHT * nutrient_mismatch + TASTINESS_DISTANCE_WEIGHT * distance + TASTINESS_DEFENCE_WEIGHT * bdef)`
- Direction of effects (all else equal):
  - larger nutrient mismatch lowers score,
  - larger distance lowers score,
  - larger defence (`bdef`) lowers score,
  - larger shoot biomass (`ms`) increases score (log-saturating bonus),
  - functional-type multipliers (`herb_type`) up/down-weight grass vs woody plants.
- Hard zero-weight constraints:
  - `distance > DETECTION_DISTANCE`,
  - `ms <= MIN_SHOOT`,
  - browser/mixed candidates beyond browse reach (`LEAF_HEIGHT * height > BROWSE_HEIGHT`, when `height` exists).
- `pick_a_plant()` samples stochastically in proportion to these weights; fixed seed yields deterministic frequencies.

Controlled selection-contract artefacts are written by `run_selection_contract_scenario()` under:
- `artefacts/canonical_runs/selection_contract_v0/`

## Movement contract policy (WP-0.4.4)

Current v0.4.4 behavior:
- Movement toward targets uses toroidal shortest-path geometry through `herbivore_move()`.
- Per-minute movement distance is capped at:
  - `max_distance = fv_max * 60`
- While in `MOVING` state with a valid target:
  - target is retained unless a disruption draw succeeds,
  - disruption draw probability is `movement_disruption_prob` (defaults to `MOVEMENT_DISRUPTION_PROB`).
- Disrupted or invalid targets trigger stochastic reselection via plant-selection weights.

Controlled movement-contract artefacts are written by `run_movement_contract_scenario()` under:
- `artefacts/canonical_runs/movement_contract_v0/`

## Foraging-rate and defence handling contract (WP-0.4.5)

Current v0.4.5 behavior in `herbivore_eat()`:
- Defence-adjusted handling limit (kg DM per minute):
  - `handling_limit_kg = (1 / handling_time / 1000) * (1 - defence_fraction)`
  - `defence_fraction = bdef / (bleaf + bstem + bdef)`
- Per-minute realized intake is the minimum of:
  - `handling_limit_kg`,
  - remaining gut capacity (`(gut_capacity - gut_content) / 1000`),
  - edible shoot above floor (`(bleaf + bstem + bdef) - MIN_SHOOT`),
  - mechanical cap (`MAX_BITE_FRACTION * gut_capacity / 1000`).
- Intake is allocated proportionally across `bleaf`, `bstem`, and `bdef`.
- Residual-biomass floor:
  - each feeding event preserves at least `MIN_SHOOT` kg shoot biomass per plant.
- Daily tracking:
  - `intake_total_day` (g DM/day) and `intake_defence_day` (g defence DM/day) are incremented from per-minute intake.

Controlled foraging-contract artefacts are written by `run_foraging_contract_scenario()` under:
- `artefacts/canonical_runs/foraging_contract_v0/`

## Digestion model v1 contract (WP-0.4.6)

Current v0.4.6 behavior:
- Digestion queues are tracked hourly and shifted once per simulated hour.
- `MRT` is an explicit parameter in hours and must lie in `[MRT_MIN_HOURS, MRT_MAX_HOURS]`.
- Queue initialization uses a non-zero steady-state fill assumption:
  - total seeded gut biomass (g) = `gut_capacity * DIGESTION_INIT_FILL_FRACTION`
  - seeded biomass is distributed across `bleaf`, `bstem`, `bdef` using
    `DIGESTION_INIT_LEAF_FRACTION`, `DIGESTION_INIT_STEM_FRACTION`, `DIGESTION_INIT_DEFENCE_FRACTION`
  - digestible carbohydrate and protein queues are seeded from those biomass pools using the same conversion factors as minute-level intake scheduling.
- Queue resizing for `MRT` changes preserves queued mass totals by redistributing each queue uniformly across the new queue length.

Expected directional effects:
- shorter `MRT` releases digestible energy earlier (higher day-1 release under matched seeded gut content),
- longer `MRT` delays release but remains finite and non-negative,
- default large-herbivore runs avoid pathological “all-zero day-1 digestion” behavior due to non-zero queue initialisation.

Controlled digestion-contract artefacts are written by `run_digestion_contract_scenario()` under:
- `artefacts/canonical_runs/digestion_contract_v1/`

## Water balance v1 contract (WP-0.4.7)

Current v0.4.7 behavior:
- Forage water intake is accrued during feeding based on available shoot water:
  - `water_per_kg_dm = qshoot / (bleaf + bstem + bdef)`
  - `forage_water_intake_kg = intake_dm_kg * water_per_kg_dm` (bounded by remaining `qshoot`).
- Plant `qshoot` is reduced by consumed forage water.
- End-of-day water accounting explicitly tracks:
  - `daily_water_requirement` (temperature-scaled in daily runner),
  - `intake_water_forage`,
  - `metabolic_water_day`,
  - `intake_water_drinking` (deficit-closure term),
  - `daily_net_water_balance = metabolic + forage + drinking - requirement`,
  - cumulative `water_balance` (sum of daily net balances).
- Drinking penalty:
  - when deficit is positive, `distance_moved` increments by `DIST_TO_WATER`,
  - this distance increment contributes an energetic cost through `calc_daily_energy_balance()`.

Expected directional effects:
- under low forage-water availability, drinking triggers and adds distance/energy cost,
- under high forage-water availability, drinking is not required,
- all water-accounting terms remain finite and internally consistent.

Controlled water-contract artefacts are written by `run_water_contract_scenario()` under:
- `artefacts/canonical_runs/water_contract_v1/`

## Nutrient-targeting vs energy-only day-in-life contract (WP-0.4.8)

Current v0.4.8 behavior:
- Herbivore state includes a discrete foraging-objective toggle:
  - `foraging_mode = \"nutrient_targeting\"` (default),
  - `foraging_mode = \"energy_only\"`.
- Selection and persistence logic coupling:
  - in nutrient-targeting mode, `DP:DC` mismatch is weighted in tastiness/persistence terms,
  - in energy-only mode, nutrient mismatch weighting is disabled and only non-nutrient terms drive those decisions.
- Controlled comparison helper:
  - `run_day_in_life_comparison()` runs matched-seed paired scenarios:
    - `day_in_life_nutrient_targeting_v1`
    - `day_in_life_energy_only_v1`
  - and emits a comparison/report bundle under:
    - `artefacts/canonical_runs/day_in_life_mode_comparison_v1/`

Expected directional effects:
- nutrient-targeting should increase intake share from plants closer to the configured nutrient target,
- energy-only should shift selection toward non-nutrient score drivers (size/distance/defence),
- paired runs should show a measurable difference in at least one defined intake/selection metric.

## Citations named in constants

- Jeschke, J.M. and Tollrian, R. (2005).
- Kleiber, M. (1961).
- McFarlane, W.V. (1965).
- Muller et al. (2013).
- Shipley et al. (1994, 1996).
- Taylor et al. (1980).

Conversion factors and digestibility parameters in `CONSTANTS` are annotated inline in `R/constants.R` (Felton et al. 2017; Giger-Reverdin and Gihad 1991; Tilley et al. 1969; Navas-Camacho et al. 1993).
