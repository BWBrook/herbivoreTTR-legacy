# Closure Tests

## Overview
Closure tests confirm functional and numerical parity with the C++ implementation and verify core biological and simulation unit correctness in the R translation.

## Unit Sanity Checks
### Test: Single Plant Transport Sanity
- Objective: Confirm `transport_resistance()` yields valid (finite, nonnegative) plant pool values for a single plant over one day.
- Procedure:
  1. Create one plant and one day of conditions.
  2. Run `transport_resistance()`.
  3. Check all pool outputs for absence of NaN/Inf, and all values are ≥ 0.
- Expected Outcome: All pools finite and nonnegative; no computational errors.
- Troubleshooting: If NaN/Inf or negatives appear, check for divide-by-zero or missing guard logic.

### Test: Herbivore Step Sanity
- Objective: Ensure single herbivore simulation consumes and moves as expected over a one-minute day.
- Procedure:
  1. Initialize single plant and herbivore.
  2. Run a herbivore step for one simulated minute.
  3. Verify plant depletion and herbivore gut increments (kg↔g conversion correctness).
- Expected Outcome: Gut increases by Δ_kg × 1000 g, plant decreases by Δ_kg.
- Troubleshooting: If not, audit the kg/g interface and eat logic.

## Integration Tests
### Test: 3-Day Run (Short-term Balances)
- Objective: Validate simulation balances remain finite and biologically plausible over three days.
- Procedure:
  1. Initialize simulation with one or more plants/herbivores.
  2. Run for 3 days, with `minute_limit=60`.
  3. Review main plant and herbivore pools for runaway or negative values.
- Expected Outcome: All pools remain finite, no runaway growth or collapse.
- Troubleshooting: Check timestep logic, integration, and pool update mechanisms if failed.

### Test: 10-Day Spin-up (Vegetation)
- Objective: Ensure vegetation growth tracks environmental forcing in absence of herbivory.
- Procedure:
  1. Disable herbivores.
  2. Run 10 days of simulation.
  3. Inspect plant growth/regression relative to conditions.
- Expected Outcome: Vegetation responds to forcing; no numerical instability.
- Troubleshooting: Adjust forcing or model parameters as needed.

### Test: 10-Day Run with Herbivory
- Objective: Verify plant decline near herbivores, reasonable herbivore balances, and daily distance.
- Procedure:
  1. Enable herbivores with a fixed position.
  2. Run 10 days.
  3. Confirm plants near the herbivore decline, herbivore balances are reasonable, and daily distances approximate `fv_max × foraging_minutes`.
- Expected Outcome: Matching trends with C++ outputs; expected patterns observed.
- Troubleshooting: If mismatched, review spatial/behavioral logic.

## Seeds & Determinism
### Test: Fixed Seed Repeatability
- Objective: Guarantee simulation returns identical results under fixed RNG seeds.
- Procedure:
  1. Set RNG seed prior to selection and movement steps.
  2. Run identical simulation twice.
  3. Compare outputs for equality.
- Expected Outcome: Outputs match exactly.
- Troubleshooting: Investigate instances of nondeterminism or hidden state if disparity is found.

For each test, the user should report success/failure by checking numeric outputs, reviewing CSV logs, or verifying within R via automated test assertions. For failures, suggested error sources and fixes are noted per test section.

After each test or update, validate outputs for correctness (e.g., value ranges, determinism, parity with C++ benchmarks). If discrepancies are detected, self-correct or provide actionable recommendations for resolution.

If all closure tests pass, the R implementation faithfully mirrors C++ functionality. Otherwise, address failures and rerun before finalizing. Once complete, ensure the closure test protocol is versioned and part of the repo documentation.

