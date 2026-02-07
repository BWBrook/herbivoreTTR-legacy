# Independent Ecological Review Memo (2026-02-07)

## 1) Scope Reviewed

Target reviewed:
- Repository state at `main` HEAD (`1c5c658`), including completed roadmap through `WP-1.0.4`.

Artefacts and evidence reviewed:
- Roadmap and decisions:
  - `docs/roadmap.md`
  - `docs/decisions.md`
- Work-package interpretation logs:
  - `docs/log/20260206_wp-0.6.3_experiment_a_presence_vs_removal.md`
  - `docs/log/20260206_wp-0.6.4_experiment_b_functional_types.md`
  - `docs/log/20260206_wp-0.6.5_experiment_c_aridity_gradient.md`
  - `docs/log/20260206_wp-1.0.4_rc_bundle_signoff_ready.md`
- Scenario definitions:
  - `config/scenarios/reference_*.yaml`
- Experiment outputs:
  - `artefacts/canonical_runs/experiment_a_presence_removal_v1/*`
  - `artefacts/canonical_runs/experiment_b_functional_types_v1/*`
  - `artefacts/canonical_runs/experiment_c_aridity_gradient_v1/*`
  - `artefacts/canonical_runs/day_in_life_mode_comparison_v1/*`
  - `artefacts/canonical_runs/smoke_v0/*`
  - `artefacts/canonical_runs/reference_*_v1/*`
- Release/reproducibility evidence:
  - `artefacts/release_candidates/v1.0.0-rc1/release_checklist_status.csv`
  - `artefacts/reproducibility/external_run_v1/repro_check_summary.csv`
  - `artefacts/reports/paper_pipeline.html`

Commands executed (read-only / non-mutating):
- `git status --short --branch`
- `git log --oneline --decorate -n 8`
- `cat`/`sed` over the files above
- targeted `R -q -e` summaries of experiment outputs and manifest seeds

## 2) Recommendation

**APPROVE WITH CHANGES**

Interpretation:
- The simulation system is reproducible, organized, and already generating coherent mechanism-level ecological signals.
- Before publication-grade ecological inference, several **major interpretation risks** should be addressed.

## 3) What Is Working Well Ecologically

1. Directional herbivory signal is present:
- In Experiment A, removal increases vegetation structure and fine-fuel proxies relative to herbivore presence.

2. Functional-type behavior is clearly differentiated:
- Grazer/browser/mixed feeding patterns are distinct and directionally sensible.

3. Aridity gradient produces strong water-demand signal:
- Drinking demand increases low -> mid -> high as expected.

4. Vegetation structure/fuel outputs are systematic and traceable:
- `structure_fuel_daily.csv` is available across scenarios with run manifests and schema versioning.

5. Reproducibility scaffolding is strong:
- Release checklist and external reproducibility run-through both pass with explicit artefact paths.

## 4) Findings (Ranked by Severity)

### MAJOR — Experiment A comparison is confounded by different seeds while report states matched seed

Evidence:
- `config/scenarios/reference_presence_present_v1.yaml`: `runtime.seed: 301`
- `config/scenarios/reference_presence_removed_v1.yaml`: `runtime.seed: 302`
- `artefacts/canonical_runs/experiment_a_presence_removal_v1/experiment_a_report.md` states: “Paired scenarios with matched runtime seed and climate settings.”

Why it matters ecologically:
- Presence-vs-removal attribution should isolate herbivory treatment effects.
- Different random seeds introduce unnecessary stochastic confounding in a causal contrast.

Proposed fix:
- Use identical seed for present and removal scenarios in paired contrasts.
- Recompute Experiment A and report deltas with matched-seed design.

Suggested verification:
- Re-run Experiment A with matched seeds and compare deltas to current values.
- Report sensitivity of effect size to seed choice (at least a small seed ensemble).

### MAJOR — Experiment C expected “intake limitation” is not observed (DMI invariant across gradient)

Evidence:
- `artefacts/canonical_runs/experiment_c_aridity_gradient_v1/experiment_c_summary.csv`:
  - `mean_daily_dmi` is effectively identical for `low`, `mid`, `high`.
- `artefacts/canonical_runs/experiment_c_aridity_gradient_v1/experiment_c_report.md` expected direction includes intake constraint with aridity.

Why it matters ecologically:
- The current gradient appears to strongly affect water stress and vegetation, but not herbivore intake.
- If interpreted as “aridity constrains intake,” this overstates current evidence.

Proposed fix:
- Reframe claim to: “water-demand and vegetation signals detected; intake limitation not yet detected under current settings.”
- Add one additional stress axis likely to influence intake directly (for example lower forage availability, lower minute budget, or altered bite/handling constraints).

Suggested verification:
- Run a small sensitivity grid and test whether DMI changes monotonically under stronger productivity constraints.

### MAJOR — Herbivore energetic state shows persistent large deficits without biological feedback

Evidence:
- `artefacts/canonical_runs/smoke_v0/herbivore_daily.csv` and `artefacts/canonical_runs/reference_aridity_*_v1/herbivore_daily.csv`:
  - `EnergyBalance` becomes increasingly negative over days.
  - No associated body-condition or mortality feedback is represented in these runs.

Why it matters ecologically:
- For publication interpretation, persistent deficits without state feedback can weaken conclusions about herbivore viability or long-horizon system behavior.
- Results are useful mechanistically, but should not be presented as realistic population outcomes.

Proposed fix:
- Document this explicitly as a current model boundary in ecological interpretation sections.
- In next roadmap line, prioritize body-condition/demography coupling if long-horizon herbivore outcomes are a goal.

Suggested verification:
- Add an interpretation check that flags sustained deficits and labels outputs as “mechanism only” for those conditions.

### MINOR — Comparative experiments rely on single deterministic runs (limited uncertainty quantification)

Evidence:
- Experiment bundles provide one summary per scenario with fixed seeds.
- No confidence intervals or across-seed variability in `experiment_*_summary.csv` outputs.

Why it matters ecologically:
- Single-seed contrasts are useful for mechanism checks but weak for inference robustness.

Proposed fix:
- Add lightweight replicate ensembles (for example 10-30 seeds) for core headline contrasts.
- Report median and interval metrics for A/B/C.

Suggested verification:
- Confirm directional conclusions remain stable across seed ensembles.

### MINOR — Unit clarity in experiment summaries could be improved for ecological readers

Evidence:
- `docs/output_contract_v1.md` lists required columns but not explicit units per field.
- Experiment reports present values (DMI, water, energy) without unit reminders.

Why it matters ecologically:
- Ambiguous units reduce interpretability and comparability with field datasets.

Proposed fix:
- Add unit annotations in experiment summary CSV headers/doc text (or companion metadata).

Suggested verification:
- Ensure each reported metric in `experiment_*_report.md` includes unit context.

### NIT — Canonical naming mismatch may confuse non-technical users

Evidence:
- Scenario id uses `canonical_smoke_v1`, while output slug/folder remains `smoke_v0`.

Why it matters ecologically:
- Increases friction when mapping scenarios to artefacts in manuscripts.

Proposed fix:
- Harmonize naming, or document this alias very prominently in user-facing docs.

Suggested verification:
- Ask a fresh user to locate canonical outputs from docs only and measure ambiguity.

## 5) Evidence Quality Audit

Verified with strong evidence:
- Reference/experiment artefacts exist with manifests.
- Release checklist is all-pass.
- External reproducibility run-through is all-pass.
- Core directional signals in A/B and water-demand gradient in C are present in raw CSVs.

Could not fully verify from current evidence set:
- Figure-level visual interpretability for manuscript quality (I audited underlying tables/reports rather than visual design quality).
- Statistical robustness of conclusions under stochastic variability (single-seed design dominates current experiment summaries).

Missing evidence for stronger ecological claims:
- Replicate/uncertainty analysis for key contrasts.
- Explicit quantitative acceptance criteria linking ecological expectations to thresholds (beyond directionality).

## 6) Risk Register Deltas

1. **Confounded treatment contrast (Experiment A seeds mismatch)**
- Likelihood: Medium
- Impact: High
- Mitigation: enforce matched seeds for paired treatment contrasts.

2. **Over-claim risk in aridity intake limitation narrative**
- Likelihood: High
- Impact: Medium-High
- Mitigation: revise wording now; extend gradient test settings to probe intake sensitivity.

3. **Energetic-deficit interpretation risk**
- Likelihood: High
- Impact: High (if interpreted as realistic herbivore outcomes)
- Mitigation: add explicit scope boundary in reports; prioritize physiological/demographic feedback roadmap.

4. **Low uncertainty quantification**
- Likelihood: High
- Impact: Medium
- Mitigation: small seed-ensemble summaries for A/B/C headline metrics.

## 7) Questions for CoS/PI (Decision-Level)

1. Should paired ecological contrasts (for example Experiment A) be formally required to use matched seeds as a protocol rule?
2. For publication narrative, do we want to label current experiments as “mechanism demonstration” only until ensemble uncertainty is added?
3. Is adding a lightweight multi-seed uncertainty layer the highest-priority next scientific upgrade, ahead of new biological modules?

---

## Practical Verification Steps (for maintainers)

Use these to reproduce the core review checks quickly:

```bash
# Release/repro evidence
cat artefacts/release_candidates/v1.0.0-rc1/release_checklist_status.csv
cat artefacts/reproducibility/external_run_v1/repro_check_summary.csv

# Experiment summaries
cat artefacts/canonical_runs/experiment_a_presence_removal_v1/experiment_a_summary.csv
cat artefacts/canonical_runs/experiment_a_presence_removal_v1/experiment_a_expected_direction.csv
cat artefacts/canonical_runs/experiment_b_functional_types_v1/experiment_b_summary.csv
cat artefacts/canonical_runs/experiment_c_aridity_gradient_v1/experiment_c_summary.csv

# Seed audit for paired contrasts
cat config/scenarios/reference_presence_present_v1.yaml
cat config/scenarios/reference_presence_removed_v1.yaml
```

