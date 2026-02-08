# Wiring Test Plan

This document outlines a practical sequence to sanity‑check that the herbivore and plant
subsystems are correctly wired and ready for deeper testing and extension. Each step lists
the intent, a minimal procedure, and expected outcomes. Execute in a clean R session from the
project root unless noted. Prefer `devtools::test()` for full runs; individual checks can be
run interactively.

Note: For direct `testthat::test_dir()` runs (without `devtools::test()`), the helper
`tests/testthat/helper-ttr.R` sources all `R/*.R` and ensures the magrittr pipe `%>%` is
available. This avoids brittle per‑file sourcing.

## 0) Quick smoke: package loads and basic init

- Intent: Confirm package compiles/loads, and core init helpers return sensible objects.
- Do:
  - `devtools::document()` then `devtools::load_all()` (or `devtools::install()`).
  - Call `init_simulation()` and inspect structure.
- Expect:
  - A list with `conditions` (data.frame), `plants` (data.frame), `herbivore` (list).
  - No warnings or errors; numeric columns finite and non‑negative.

## 1) Unit helpers: envelopes and Monod

- Intent: Validate mathematical helpers used throughout TTR forcing.
- Do:
  - `trap1()`, `trap2()`, `monod()` on small vectors including edge/degenerate cases.
- Expect:
  - Bounded results in `[0, 1]` with finite outputs; zero‑width ramps handled gracefully.

## 2) Transport resistances and rates

- Intent: Check resistance functions and transport rates are finite and with expected signs.
- Do:
  - `calc_RsC/RrC/RsN/RrN` over vectors of masses and `Q` values; include zeros/NA/Inf.
  - Build a toy plant list and evaluate `calc_tauC/tauN/tauCd/tauNd`.
- Expect:
  - Finite, non‑negative resistances; extremely small masses capped, not `Inf/NaN`.
  - `tauC > 0` when `Cs/Ms > Cr/Mr`; `tauN > 0` when `Nr/Mr > Ns/Ms`; zeros with zero masses.

## 3) Uptake and growth primitives

- Intent: Ensure uptake (`calc_UC/UN`) and growth (`calc_Gs/Gr/Gd`) are finite and respect
  zero‑mass guards.
- Do:
  - Call with valid toy plant; then set `ms` or `mr` to zero.
- Expect:
  - Finite, non‑negative outputs; zeros when relevant masses are zero.

## 4) TTR orchestrator wiring

- Intent: Verify `transport_resistance()` advances plant state per day and keeps invariants.
- Do:
  - Create `conditions <- init_conditions(days_in_year = 10, mode = "flat", mean_temp = 20,
    amplitude = 0)`.
  - `plants <- init_plants()`; call `transport_resistance(plants[1,], conditions, 1)`.
- Expect:
  - Output has same columns; all finite; `ms, mr, bleaf, bstem, bdef >= 0`.
  - `uc`, `un`, `gs`, `gr` populated and finite.

## 5) Herbivore local mechanics: range, selection, intake

- Intent: Confirm foraging primitives work and interact with plant rows.
- Do:
  - Place a browser and a plant above browse height; check `get_plants_within_range()` filters.
  - Use a single plant within eat radius; set generous capacity; call `herbivore_eat()`.
- Expect:
  - Unreachable tall plants excluded for browsers.
  - Plant mass decreases by `delta_kg`; herbivore gut content increases by `delta_kg * 1000` g.

## 6) One‑minute and short‑day smoke

- Intent: Exercise the daily runner with minimal minute counts.
- Do:
  - `sim <- init_simulation()`; run `run_daily_herbivore_simulation(sim$herbivore, sim$plants,
    sim$conditions, minute_limit = 1)`.
  - For an active herbivory day, set day beyond spin‑up and `minute_limit = 60`.
- Expect:
  - Returns list with `herbivore`, `plants`, `daily_record`, `daily_summary`.
  - Finite `energy_balance`, `water_balance`; plant masses remain non‑negative.

## 7) Spin‑up gating

- Intent: Validate herbivory is disabled during spin‑up and enabled afterward.
- Do:
  - Run day 1 with default `CONSTANTS$SPIN_UP_LENGTH`; then a day immediately after spin‑up.
- Expect:
  - Day 1: `intake_total_day == 0`, `distance_moved == 0`.
  - Post spin‑up: positive `intake_total_day` and reduced plant mass if within range.

## 8) Integration: daily wiring and invariants

- Intent: Ensure `run_daily_herbivore_simulation()` applies plant TTR update before herbivory,
  then performs movement/intake, and ends with budget updates.
- Do:
  - Run an active day with `minute_limit = 60`; compare pre vs post plant columns contain
    `uc`, `gs` etc.
- Expect:
  - `uc`, `gs` set before any herbivory; plants remain finite and non‑negative.

## 9) Writers parity check (optional)

- Intent: Confirm writers produce stable semicolon CSVs suitable for parity diffs.
- Do:
  - Use `write_plants_daily()` and `write_herbivores_daily()` on small snapshots.
- Expect:
  - Exact header matches the expected order; body contains semicolons; no `NA/NaN/Inf`.

## 10) Multi‑day feed‑forward

- Intent: Check that plant and herbivore states feed into subsequent days without drift to
  invalid ranges.
- Do:
  - Run 7 consecutive 60‑minute days, feeding `herbivore` and `plants` forward each day.
- Expect:
  - Finite `energy_balance` and `water_balance` after day 7; all plant pools finite and
    non‑negative; rough upper bounds (e.g., < 1e6) not exceeded.

---

## Sanity assessment and caveats

Wiring status (as implemented):

- Plant TTR orchestrator `transport_resistance()` is self‑contained and uses available helpers:
  `trap1/trap2`, `monod`, resistances `calc_R*`, rates `calc_tau*`, uptake `calc_UC/UN`,
  growth `calc_Gs/Gr`, and pool RHS `calc_d*`. Defence growth and defence transport are
  disabled to mirror the current C++ parity focus.
- The daily runner `run_daily_herbivore_simulation()` calls `transport_resistance()` once per
  day before herbivory, gates herbivory with a spin‑up window, executes minute‑resolution
  behaviour via `herbivore_step()`, and finalises water and energy balances.
- Herbivore primitives are available: `get_plants_within_range()`, `calc_plant_tastiness()`,
  `pick_a_plant()`, `herbivore_move()`, `herbivore_eat()`, with allometric traits supplied by
  `calc_foraging_traits()`.
- Writers exist and validate output: `write_plants_daily()` and `write_herbivores_daily()`.

Energy and defence notes:

- Energy units are standardized to kJ. Digested carbohydrate/protein masses are tracked in grams
  (`dc_*`, `dp_*`) and converted to kJ in `hourly_digestion_step()` via `CARB_TO_ENERGY` and
  `PROTEIN_TO_ENERGY` (kJ per gram) — no extra scaling factor.
- Functions that use the magrittr pipe `%>%` are sourced in tests via the helper, which ensures
  `%>%` is available. When testing without `devtools::load_all()`, keep this in mind.
- Defence‑related transport and growth are disabled by default; set
  `CONSTANTS$DEFENCE_ENABLED <- 1` to enable `rdC/rdN`, `tauCd/tauNd`, and `gd` wiring in the
  orchestrator. Add tests for expected signs when enabled.

Conclusion: The model is logically wired for initial testing and energy/defence updates. Proceed
with the sequence above.
