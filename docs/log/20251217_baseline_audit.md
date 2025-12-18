# Baseline audit (WP-0.3.1) — 2025-12-17

Repo: `herbivoreTTR`  
Git SHA: `ea98517509ece88704633715c669cfae002563ce`  
Host: Ubuntu 24.04.3 (x86_64)  
R: 4.5.2 (2025-10-31)  

## Goal
Establish a single source of truth for the current “passes/fails” state of the repo’s quality gates:
- reproducibility (`renv::restore()` from a clean library),
- package health (`R CMD check --as-cran`),
- tests,
- lint,
- targets smoke (`TARGETS_PROFILE=ci`).

This log captures failures verbatim and proposes the shortest unblock path toward MVP v0.1.0 / Roadmap line 0.3.x.

---

## 1) Reproducibility: `renv::restore()` from a clean state

I simulated a “clean machine” by restoring into an empty, repo-local library directory:

Command:
```bash
R -q -e 'dir.create(".cache/renv_audit_lib", recursive = TRUE, showWarnings = FALSE); renv::restore(prompt = FALSE, clean = TRUE, library = ".cache/renv_audit_lib")'
```

Result: **SUCCESS** (packages copied from cache / installed as needed).

Notes:
- A subsequent `renv::restore(prompt = FALSE, clean = TRUE)` against the *active* project library removed `lintr` and several dev-only packages, indicating they are **not recorded in `renv.lock`** and will not be present after a clean restore.

---

## 2) Unit/integration tests (`testthat`)

Command:
```bash
make test
```

Result: **FAIL** (2 failing tests).

Failure (verbatim):
```text
Failure ('test_energy_water_balance.R:24:3'): calc_daily_energy_balance matches manual computation
updated$energy_balance (`actual`) not equal to `expected` (`expected`).

  `actual`:   -34756.0
`expected`: -6546546.5
```

Failure (verbatim):
```text
Error ('test_hygiene.R:17:3'): calc_plant_tastiness uses bdef and returns finite values
Error in `eval(substitute(expr), data, enclos = parent.frame())`: object 'ms' not found
Backtrace:
    ▆
 1. └─herbivoreTTR::calc_plant_tastiness(...) at test_hygiene.R:17:3
 2.   ├─base::with(...) at herbivoreTTR/R/calc_plant_tastiness.R:17:3
 3.   └─base::with.default(...)
 4.     └─base::eval(substitute(expr), data, enclos = parent.frame())
 5.       └─base::eval(substitute(expr), data, enclos = parent.frame())
```

Likely root causes:
- `calc_daily_energy_balance()` converts `mass` from g → kg before applying Kleiber/Taylor allometries, but the test computes the expected value using raw grams.
- `calc_plant_tastiness()` assumes a `ms` (shoot mass) column exists, but the “hygiene” test intentionally supplies a minimal `plants_in_range` without `ms`.

Next actions:
- Align the energy balance test with the package’s mass-unit convention (g stored, kg used in the energy allometries).
- Make `calc_plant_tastiness()` robust to minimal inputs (treat size bonus as optional when `ms` is absent).

---

## 3) Lint gate (`lintr`)

Command:
```bash
make lint
```

Result: **FAIL** (tooling not installed after clean restore).

Failure (verbatim):
```text
Error in loadNamespace(x) : there is no package called ‘lintr’
Calls: loadNamespace -> withRestarts -> withOneRestart -> doWithOneRestart
Execution halted
```

Likely root cause:
- `{lintr}` is not declared as a dependency (and is not captured in `renv.lock`), so a clean restore will remove it.

Next actions:
- Add `{lintr}` to `DESCRIPTION` (Suggests) and snapshot `renv.lock` after installing it.

---

## 4) Targets smoke run (`TARGETS_PROFILE=ci`)

Command:
```bash
make smoke
```

Result: **FAIL** (Makefile calls an argument no longer supported by the installed `{targets}`).

Failure (verbatim):
```text
Error in targets::tar_make(callr_function = NULL, ask = FALSE) : 
  unused argument (ask = FALSE)
Execution halted
```

Likely root cause:
- The repo’s Makefile uses `ask = FALSE` for `targets::tar_make()`, but the installed `{targets}` (from `renv.lock`) does not accept `ask`.

Next actions:
- Update `make smoke` to call `targets::tar_make(callr_function = NULL)` without `ask`.

---

## 5) Package health (`R CMD check --as-cran`)

### 5.1 Check on source directory (fails early)
Command:
```bash
R CMD check --as-cran --no-manual --timings .
```

Result: **FAIL** with:
```text
* checking for file ‘./DESCRIPTION’ ... ERROR
Required fields missing or empty:
  ‘Author’ ‘Maintainer’
```

Observation:
- Running `R CMD build .` succeeds and the built tarball’s `DESCRIPTION` includes `Author:` and `Maintainer:` fields derived from `Authors@R`.
- Checking the *built tarball* works (see below), suggesting this failure is specific to “check a directory” mode in this environment.

### 5.2 Check on built tarball (succeeds, but not clean)
Commands:
```bash
R CMD build .
R CMD check --as-cran --no-manual --timings herbivoreTTR_0.0.0.9000.tar.gz
```

Result: **SUCCESS with 6 WARNINGs and 6 NOTEs**.

High-impact issues flagged by check:
- Build includes repo-local `.cache/…` content (from the clean restore test), producing:
  - huge tarball size,
  - warnings about executable files inside the source package,
  - notes about non-portable file paths.
- License metadata note: `License: MIT` should be `MIT + file LICENSE`.
- Undeclared dependencies via `pkg::fun` usage (e.g. `renv`, `pak`, `lgr`, `progressr`).
- Missing documentation entries for exported objects (no `man/*.Rd` present).
- Top-level `data/` directory structure is non-standard for R packages; `R CMD check` warns about non-dataset contents under `data/`.

Next actions:
- Add `.cache/` (and other non-package artefacts) to `.Rbuildignore` and remove any accidental `.cache` content from the repo tree.
- Fix license field.
- Generate roxygen docs for exported API (stable surface per `docs/decisions.md`).
- Declare tooling dependencies needed by tests/lint/targets.

---

## Triage register (blockers → roadmap WPs)

**CI / production blockers (must fix for MVP v0.1.0)**
- Tests failing (energy unit mismatch; `calc_plant_tastiness()` robustness) → WP-0.3.7 (sanity + invariants) + immediate bugfix.
- Targets smoke broken due to `ask` arg mismatch → WP-0.3.2.
- Lint gate broken after clean restore (missing `{lintr}` in lockfile) → WP-0.3.2.
- No roxygen reference docs for exports → MVP deliverable + WP-1.0.1 precursor.
- Package build polluted by `.cache` → WP-0.3.1 hygiene; blocks meaningful `R CMD build/check`.

**Important but can be staged**
- R CMD check “directory mode” complaining about Author/Maintainer → either add explicit fields or standardise on tarball/devtools check workflow.
- Data-directory packaging warnings → decide whether to treat this repo as a CRAN-style package or as a “research package + pipeline”; document rationale and enforce via CI accordingly.

