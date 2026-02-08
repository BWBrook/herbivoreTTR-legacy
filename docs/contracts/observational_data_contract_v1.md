# Observational Data Contract v1

This contract defines the canonical tabular format used to compare external
ecological observations with model outputs.

## Required columns

- `site_id` (character): site or location identifier.
- `day_index` (integer): positive day index aligned to model summary horizon.
- `metric_name` (character): metric key (for example `mean_daily_dmi`).
- `value` (numeric): observed value for the metric/day.
- `unit` (character): unit label from `config/units/metric_units_v1.csv`.
- `uncertainty` (numeric): optional uncertainty (NA allowed).

## Adapter entry points

- `adapt_vegetation_timeseries_v1()`
- `adapt_herbivore_timeseries_v1()`
- `validate_observational_data_v1()`

## Example datasets

Synthetic adapter fixtures are provided in:

- `inst/extdata/validation/vegetation_timeseries_example.csv`
- `inst/extdata/validation/herbivore_timeseries_example.csv`

These are for contract and pipeline validation only, not ecological inference.
