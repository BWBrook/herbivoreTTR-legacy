# Working with R & `renv` (Full-Access Setup)

This repository now runs with normal filesystem permissions, so the standard `renv` workflow applies. The notes below summarise how to work with the project and how to recover if you ever need to fall back to a sandboxed environment again.

## 1. Default Assumptions
- `$HOME` and the usual XDG cache locations are writable.
- `renv` loads automatically via `.Rprofile` (`source("renv/activate.R")`).
- The global cache lives at `~/.cache/R/renv`, so packages installed for one project are automatically reused by others.
- `.Renviron` sets `RENV_CONFIG_SANDBOX_ENABLED=FALSE` so tests that rely on `pkgload::load_all()` see base packages (e.g. `parallel`) directly from the system library.

Nothing special needs to be exported before running R; simply call `R`, `Rscript`, or the supplied `Makefile` targets.

## 2. Typical Workflow
```bash
# restore packages from renv.lock
R -q -e 'renv::restore(prompt = FALSE)'

# check consistency
R -q -e 'renv::status()'

# add/remove dependencies as usual (install.packages / renv::install)
# then capture the state
R -q -e 'renv::snapshot(prompt = FALSE)'
```

The project library is stored under `~/.cache/R/renv/library/<project-id>/...` and points into the shared cache.

## 3. Running Tooling
- `make setup` – initialise or restore the environment.
- `make run` / `make smoke` – execute the `{targets}` pipeline.
- `make test` – run `testthat::test_dir(...)`.
- `make lint` – run `lintr::lint_package()` and fail if any lints remain.
- `make render` – render `reports/paper.qmd` with Quarto.
- Commands can also be run manually, e.g. `R -q -e 'targets::tar_make()'`.

## 4. Troubleshooting & Notes
- If `requireNamespace("tarchetypes")` (or other packages) fail, run `renv::restore()` to reinstall from the lockfile.
- Base packages (e.g. `parallel`) are used directly from the system library; no extra configuration is required.
- `renv::clean()` removes unused packages from the project library; the shared cache retains binaries for reuse.

## 5. If You Must Re-Enter a Sandbox
Should you need to run in a restricted environment again, recreate the per-repo cache setup by exporting:

```bash
RENV_PATHS_CACHE=$PWD/.cache/renv \
R_USER_CACHE_DIR=$PWD/.cache/R \
XDG_CACHE_HOME=$PWD/.cache/xdg \
RENV_CONFIG_SANDBOX_ENABLED=FALSE \
RENV_CONFIG_PAK_ENABLED=FALSE \
R -q -e 'renv::restore(prompt = FALSE)'
```

This mirrors the earlier helper scripts and keeps the workflow functional even without a writable home directory. Once full access is restored you can drop the overrides and return to the defaults described above.
