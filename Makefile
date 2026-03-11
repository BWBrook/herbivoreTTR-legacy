.PHONY: setup run smoke smoke-fast smoke-deep test lint check render render-v2 clean test-battery release-bundle release-bundle-v2 repro-check repro-check-v2 rc-gates

## Initialise the project: install packages via renv, set up pre-commit
setup:
	R -q -e "source('R/packages.R'); Sys.setenv(RENV_CONFIG_PAK_ENABLED = 'FALSE'); renv::init(bare = TRUE); renv::restore(prompt = FALSE)"
	- pre-commit install || true

## Run the full pipeline
run:
	R -q -e "targets::tar_make()"

## Run deep smoke pipeline (uses CI profile)
smoke:
	$(MAKE) smoke-deep

## Run fast smoke subset of core canonical bundles
smoke-fast:
	TARGETS_PROFILE=ci R -q -e "targets::tar_make(names = c('canonical_bundle_files', 'cohort_bundle_files', 'implicit_bundle_files', 'day_in_life_bundle_files'), callr_function = NULL)"

## Run full smoke pipeline (uses CI profile)
smoke-deep:
	TARGETS_PROFILE=ci R -q -e "targets::tar_make(callr_function = NULL)"

## Run unit tests
test:
	R -q -e "testthat::test_dir('tests/testthat')"

## Run linters
lint:
	R -q -e "res <- lintr::lint_package(); if (length(res)) { print(res); quit(status = 1, save = 'no') }"

## Run R CMD check (CI style)
check:
	R -q -e "build_status <- system2('R', c('CMD', 'build', '.')); if (!identical(build_status, 0L)) quit(status = build_status, save = 'no'); pkg <- tail(sort(Sys.glob('herbivoreTTR_*.tar.gz')), 1); if (!length(pkg)) stop('No source package found after build'); check_status <- system2('R', c('CMD', 'check', '--as-cran', '--no-manual', '--timings', pkg)); if (!identical(check_status, 0L)) quit(status = check_status, save = 'no')"

## Render the Quarto report
render:
	R -q -e "for (f in list.files('R', pattern = '\\\\.R$$', full.names = TRUE)) sys.source(f, envir = globalenv()); render_paper_pipeline_report()"

## Render the post-1.0 Quarto report with figure/table manifest
render-v2:
	R -q -e "for (f in list.files('R', pattern = '\\\\.R$$', full.names = TRUE)) sys.source(f, envir = globalenv()); render_paper_pipeline_report_v2()"

## Build release candidate bundle
release-bundle:
	Rscript scripts/build_release_bundle.R

## Build post-1.0 release candidate bundle
release-bundle-v2:
	Rscript scripts/build_release_bundle_v2.R

## Run clean-environment reproducibility run-through
repro-check:
	Rscript scripts/run_external_repro_check.R

## Run clean-environment reproducibility run-through (post-1.0)
repro-check-v2:
	Rscript scripts/run_external_repro_check_v2.R

## Run full release candidate gate set
rc-gates:
	$(MAKE) test
	$(MAKE) lint
	$(MAKE) smoke
	$(MAKE) check

## Clean generated data and pipeline artifacts
clean:
	R -q -e "targets::tar_destroy(confirm = FALSE)"
	rm -rf data/interim data/processed logs

## Run full test battery (pipeline + tests + optional coverage)
test-battery:
	R -q -e "source('scripts/run_test_battery.R')"
