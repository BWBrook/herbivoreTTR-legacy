# Release checklist — herbivoreTTR

This checklist must be satisfied before tagging a release.

## Versioning & changelog
- [ ] `DESCRIPTION` version updated (SemVer)
- [ ] `CHANGELOG.md` updated (Keep a Changelog)
- [ ] Public API changes documented (including any deprecations)

## Reproducibility
- [ ] `renv.lock` updated and consistent with repository code
- [ ] Fresh install test: `renv::restore()` succeeds on a clean machine/container
- [ ] External reproducibility run-through passes (`make repro-check`)

## Quality gates
- [ ] `R CMD check --as-cran` clean on Linux
- [ ] Tests pass (including integration/pipeline-related tests)
- [ ] `lintr::lint_package()` returns zero lints
- [ ] Targets smoke run completes under CI profile

## Documentation
- [ ] README quickstart runs
- [ ] Vignettes build successfully (or are explicitly excluded with rationale)
- [ ] Roxygen docs generated and committed (or generated in release pipeline consistently)

## Artefacts
- [ ] Built source tarball produced
- [ ] Reference output bundle produced (small “golden run” outputs)
- [ ] Release candidate bundle assembled under `artefacts/release_candidates/<label>/`
- [ ] Release notes summarize:
  - what changed
  - any output differences users should expect
  - how to reproduce the reference run

## Final sanity
- [ ] Domain sanity checks reviewed (finite state, non-negativity, plausible budgets)
- [ ] `docs/decisions.md` updated if assumptions changed

## Post-1.0 hardening (v1.1 track)
- [ ] Tiered CI definitions present and validated:
  - `.github/workflows/ci.yml`
  - `.github/workflows/nightly.yml`
  - `.github/workflows/weekly_repro.yml`
- [ ] Long-horizon stability suite output present:
  - `artefacts/stability/long_horizon_v1/stability_summary_v1.csv`
- [ ] Scaling profile output + regression table present:
  - `artefacts/benchmarks/post_v1_scaling_v2/scaling_summary_v1.csv`
  - `artefacts/benchmarks/post_v1_scaling_v2/scaling_regression_check_v1.csv`
- [ ] v2 report artefacts + deterministic manifest present:
  - `artefacts/reports_v2/paper_pipeline_v2.html`
  - `artefacts/reports_v2/figure_table_manifest_v2.csv`
- [ ] External v2 reproducibility run-through passes:
  - `make repro-check-v2`
- [ ] v1.1 release bundle generated:
  - `make release-bundle-v2`
