.PHONY: setup run smoke test lint render clean test-battery

## Initialise the project: install packages via renv, set up pre-commit
setup:
	R -q -e "source('R/packages.R'); renv::init(bare = TRUE); renv::restore(prompt = FALSE)"
	- pre-commit install || true

## Run the full pipeline
run:
	R -q -e "targets::tar_make()"

## Run a smoke test pipeline (uses CI profile)
smoke:
	TARGETS_PROFILE=ci R -q -e "targets::tar_make(callr_function = NULL)"

## Run unit tests
test:
	R -q -e "testthat::test_dir('tests/testthat')"

## Run linters
lint:
	R -q -e "res <- lintr::lint_package(); if (length(res)) { print(res); quit(status = 1, save = 'no') }"

## Render the Quarto report
render:
	R -q -e "quarto::quarto_render('reports/paper.qmd')"

## Clean generated data and pipeline artifacts
clean:
	R -q -e "targets::tar_destroy(confirm = FALSE)"
	rm -rf data/interim data/processed logs

## Run full test battery (pipeline + tests + optional coverage)
test-battery:
	R -q -e "source('scripts/run_test_battery.R')"
