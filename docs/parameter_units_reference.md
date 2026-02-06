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

Canonical smoke defaults are generated by `canonical_smoke_parameters()` and consumed by `_targets.R` as `canonical_scenario_parameters`.

Defaults:
- `temp_mode = "flat"`
- `veg_types = c(0, 1, 2)`
- `herbivore_mass = 5e5` (g)
- `minute_limit = 60`
- `start_day = CONSTANTS$SPIN_UP_LENGTH * nrow(conditions) + 1`
- `days = 7`

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

## Citations named in constants

- Jeschke, J.M. and Tollrian, R. (2005).
- Kleiber, M. (1961).
- McFarlane, W.V. (1965).
- Muller et al. (2013).
- Shipley et al. (1994, 1996).
- Taylor et al. (1980).

Conversion factors and digestibility parameters in `CONSTANTS` are annotated inline in `R/constants.R` (Felton et al. 2017; Giger-Reverdin and Gihad 1991; Tilley et al. 1969; Navas-Camacho et al. 1993).
