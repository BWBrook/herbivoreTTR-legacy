# Release checklist — herbivoreTTR

This checklist must be satisfied before tagging a release.

## Versioning & changelog
- [ ] `DESCRIPTION` version updated (SemVer)
- [ ] `CHANGELOG.md` updated (Keep a Changelog)
- [ ] Public API changes documented (including any deprecations)

## Reproducibility
- [ ] `renv.lock` updated and consistent with repository code
- [ ] Fresh install test: `renv::restore()` succeeds on a clean machine/container

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
- [ ] Release notes summarize:
  - what changed
  - any output differences users should expect
  - how to reproduce the reference run

## Final sanity
- [ ] Domain sanity checks reviewed (finite state, non-negativity, plausible budgets)
- [ ] `docs/decisions.md` updated if assumptions changed
