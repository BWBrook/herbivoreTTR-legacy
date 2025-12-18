# MVP unblock: gates + docs + sanity — 2025-12-17

Git SHA (local): `ea98517509ece88704633715c669cfae002563ce` (baseline audit)  
Working tree includes additional changes after baseline; see `git status` for the full diff set.

## Summary
This pass converts the repo from “fails on first contact” to “locally green quality gates”, and lays down CI scaffolding.

Key outcomes:
- `renv::restore()` works from a clean library and `renv.lock` is updated for tooling (`lintr`, `roxygen2`).
- Tests now pass locally, and `R CMD check --as-cran` runs tests via `tests/testthat.R`.
- Lint and targets smoke run successfully (CI profile).
- Exported API is now documented (roxygen → `man/` + roxygen-generated `NAMESPACE`).
- Domain sanity invariants are enforced by tests; a real digestion-queue bug (NA/length drift) was fixed.
- GitHub Actions CI workflow added for: check, tests, lint, targets smoke, coverage.

## Reproducibility (clean restore)
Command:
```bash
R -q -e 'dir.create(".cache/renv_audit_lib", recursive = TRUE, showWarnings = FALSE); renv::restore(prompt = FALSE, clean = TRUE, library = ".cache/renv_audit_lib")'
```
Result: SUCCESS (packages restored/copied from cache).

## Quality gates (local)
Commands and outcomes:
```bash
make test
make lint
make smoke
RUN_COVERAGE=1 make test
R CMD build .
R CMD check --as-cran --no-manual --timings herbivoreTTR_0.0.0.9000.tar.gz
```

Results:
- Unit/integration tests: PASS
- Lint: PASS (configured to focus on hygiene rather than forcing a full style refactor)
- Targets smoke (`TARGETS_PROFILE=ci`): PASS
- Coverage gate: PASS (threshold set to 75%; current run ≈76%)
- `R CMD check --as-cran`: PASS (remaining warnings/notes are environmental/non-CRAN)

## What changed (high level)
### Tooling + CI
- Fixed `make smoke` for `{targets}` >= 1.11 (removed unsupported `ask = FALSE`).
- Added missing dependency declarations and refreshed `renv.lock`:
  - `lintr`, `roxygen2`, plus packages required by tests/pipeline/tooling.
- Added `.github/workflows/ci.yml` (Linux) to run:
  - `R CMD check --as-cran`,
  - unit tests,
  - lint,
  - targets smoke,
  - coverage gate.
- Installed `qpdf` in the CI check job to avoid the common PDF-size warning on Ubuntu runners.

### API docs
- Generated `man/*.Rd` for exported functions and switched to roxygen-generated `NAMESPACE`.
- Fixed roxygen markup that previously produced unresolved-link warnings (unit strings in `[]`).
- Added missing `@export` and missing parameter documentation where required by `R CMD check`.

### Domain sanity (model correctness)
- Fixed `hourly_digestion_step()` queue shifting: previously introduced `NA` and length drift; now digestion queues are normalised to length `MRT`, NAs coerced to zero, and shifting is stable.
- Hardened `calc_plant_tastiness()` to accept minimal `plants_in_range` inputs (size bonus becomes optional when `ms` is absent).
- Added a new invariant test: finite + non-negative core plant pools; finite herbivore state; gut content within capacity.

## Artefact review (spot checks)
Targets smoke outputs (example):
- `data/outputs/plants_day1826.csv`
- `data/outputs/herb_day1826.csv`

Quick checks on these outputs:
- No `NA`/`NaN`/`Inf` values in core plant pools (`Ms`, `Mr`, `BLeaf`, `BStem`, `BDef`, `Cs`, `Cr`, `Ns`, `Nr`).
- Herbivore daily summary fields are finite; energy balance can be negative but is finite.

## Decisions recorded
Updated `docs/decisions.md` with:
- explicit mass-unit conversion policy for allometries (g stored, kg in formulas),
- digestion queue contract (length = `MRT`, no NAs; shift/drop semantics).

## Remaining notes
- `R CMD check --as-cran` still reports NOTES about non-standard top-level repo files (e.g. `_targets.R`, `scripts/`, `reports/`). This is expected for a GitHub-style research compendium; CRAN submission is explicitly out of scope pre-1.0.

