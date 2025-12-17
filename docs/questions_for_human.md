# Questions for the maintainer (non-blocking)

These questions refine scope and scientific intent. Defaults are assumed in the roadmap until clarified.

## Scope & releases
1. Do you want v1.0 to support **multiple simultaneous herbivores** (a cohort) as a first-class feature?
   - Default assumed: yes (Beta introduces N-herbivore runner; v1.0 stabilizes it).

2. Do you expect a CRAN submission path, or are GitHub releases sufficient?
   - Default assumed: GitHub releases only for v1.0 (but keep R CMD check clean).

## Functional types (grazer/browser/mixed)
3. What is the intended behavioral distinction for **mixed feeders**?
   - Default assumed: mixed = interpolated preference between graze and browse (explicit policy parameter).

4. Should grazer/browser distinction primarily affect:
   - reachable plant parts (height constraints),
   - preferred biomass pools (leaf vs stem),
   - or plant type selection (veg_type filters)?
   - Default assumed: combination of reachable height + bite allocation preference.

## Nutritional targeting
5. The current implementation uses a DP:DC proxy target in selection scoring.
   - Is the “headline” target you want to communicate **NPE:PE** or **DP:DC**?
   - Default assumed: DP:DC is an implementation proxy; docs will describe it as nutrient targeting consistent with NPE:PE intent.

6. Do you have preferred literature sources for the allometric scaling relationships and energy conversions?
   - Default assumed: keep existing constants and citations embedded in code; refine once you provide references.

## Inputs & outputs
7. What output formats are most useful for downstream users?
   - Default assumed: CSV for snapshots + optional RDS for full state; stable schemas documented.

8. Do you want a “scenario YAML” interface as a primary user entry point?
   - Default assumed: primary interface is an R `scenario` list; YAML is optional sugar.

## Validation
9. How strict should parity be relative to the C++ reference?
   - Default assumed: preserve parity where tests exist; intentional changes must be documented as “scientific differences”.

## Performance expectations
10. Typical scale you care about:
   - number of plants (grid size),
   - number of herbivores,
   - days simulated,
   - desired runtime on a laptop.
   - Default assumed: small-to-medium exploratory runs (minutes to tens of minutes), with an HPC/container path for larger runs.
