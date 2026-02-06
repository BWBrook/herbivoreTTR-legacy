# Workflow — How we build and verify herbivoreTTR

This workflow is designed to keep the project scientifically trustworthy and engineering-clean.

## The iteration loop
1. **Choose a milestone task** from `docs/roadmap.md`.
2. **Make a small implementation change** (aim for a single concept per commit).
3. **Run quality gates** relevant to the change:
   - tests, lint, targets smoke, and package check as appropriate
4. **Perform the Artefact Review Cycle** (below) for any model/pipeline/output change.
5. **Document**:
   - update `docs/decisions.md` if assumptions changed
   - add a short entry under `docs/log/` describing results and outputs inspected
6. Repeat until milestone acceptance criteria are met.

## Artefact Review Cycle (scientific-style result checking)
For changes that affect model logic, outputs, or orchestration:

### 1) Build artefacts
Produce at least:
- A built package artefact (source tarball)
- A targets smoke run (CI profile)
- A small simulation output set (e.g., day-1 snapshot CSVs and/or hourly log)

### 2) Sanity (domain-level checks)
Inspect outputs and confirm:
- All numeric state is finite (no NaNs/Infs)
- Biomass pools and gut contents are non-negative
- Gut capacity constraints are respected
- Energy/water balances behave plausibly (no explosive drift in a tiny demo run)

Runtime note:
- Daily runners now fail fast with `herbivoreTTR_domain_sanity_violation` errors that include day/minute/phase and offending component. Treat these as first-class model faults.

### 3) Interpretation
Write down:
- What changed and why
- What artefacts were produced (paths)
- What you inspected (tables/plots/summaries)
- Whether outputs changed vs previous fixtures, and why that’s acceptable

Record this in `docs/log/YYYYMMDD_<topic>.md`.

### 4) Iteration
If any sanity check fails, fix and rerun the same artefact set until coherent.

## Default commands (local)
The repo provides a Makefile; use it where available:
- `make setup` — restore dependencies and set up hooks
- `make test` — run unit/integration tests
- `make lint` — run lintr
- `make smoke` — run a minimal targets pipeline under CI profile
- `make test-battery` — run the full battery (pipeline + tests + optional coverage)

## Failure handling
- If tests fail: minimize the diff, reproduce deterministically, fix root cause, and add a regression test.
- If outputs change: treat it as a scientific event—explain the change, update fixtures only with justification.
- If CI is flaky: reduce nondeterminism (seeds, parallelism), tighten tolerances, and document.

## Documentation discipline
- Public API changes require:
  - updated roxygen docs
  - updated README/vignette if user-facing
  - changelog entry (for releases)
- Any scientific assumption must be written in `docs/decisions.md`.
