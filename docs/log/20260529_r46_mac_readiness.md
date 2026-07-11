# R 4.6.0 Mac Readiness Sweep

Date: 2026-05-29

## Context

This sweep moved the Mac mini checkout away from stale R 4.5.3 pinning and
onto the host Homebrew R 4.6.0 runtime. The aim was to make the repository
fully workable on this macOS dev box after the earlier WSL setup.

## Changes

- Updated `renv.lock` for R 4.6.0 and `renv` 1.2.3.
- Removed the local `.envrc` R 4.5 override from the working setup.
- Made `Makefile` recipes use overridable `R` and `RSCRIPT` variables.
- Replaced R 4.6-sensitive quoted regexes in shell-invoked R expressions with
  `[.]R` forms.
- Replaced unavailable `pryr` memory instrumentation with `lobstr`.
- Added `scripts/dev_dependencies.R` so Makefile-only dev tools remain visible
  to `renv` dependency discovery.
- Restored `renv/settings.json` to avoid globally installing dependency
  `Suggests`; this prevents clean restores from chasing irrelevant optional
  packages such as `gifski` and `sodium`.
- Hardened external reproducibility scripts so the restore step checks
  `renv::status()` before later stages are counted as passing.

No scientific model assumptions were changed.

## Inherited Historical Verification (2026-05-29)

The results below describe the original May sweep only. They are inherited
historical evidence, not fresh Goal 001 validation and not proof of output
equivalence across the later lock refresh.

- `R -q -e 'renv::status()'`: clean.
- `make test`: 962 passed, 31 expected skips.
- `make lint`: passed with zero lints.
- `make smoke`: passed under `TARGETS_PROFILE=ci`.
- `make check`: passed with 2 expected NOTEs (`New submission`; non-standard
  top-level research-workflow files).
- `make test-battery`: passed and wrote
  `data/outputs/test_log_20260529162609.csv`.
- `make render`: generated `artefacts/reports/paper_pipeline.html`.
- `make render-v2`: generated
  `artefacts/reports_v2/paper_pipeline_v2.html`.
- `make release-bundle`: generated
  `artefacts/release_candidates/v2.0.0-rc1` with all checklist items passing.
- `make release-bundle-v2`: generated the same release-candidate bundle with
  all checklist items passing.
- `make repro-check`: passed all clean-environment v1 stages.
- `make repro-check-v2`: passed all clean-environment v2 stages.
- `actionlint`: passed.
- `git diff --check`: passed after trimming generated `renv/activate.R`
  trailing whitespace.

## Notes

The earlier `make repro-check-v2` failure was not a model or pipeline failure.
It came from restore-time dependency policy: including `Suggests` globally made
the clean isolated restore attempt optional dependency trees outside the locked
project surface. The final lock/settings now keep the project dev/test tools
locked without requiring those unrelated optional packages.

## Lock Refresh Provenance

Relative to `872fb20`, the inherited lock refresh moves R 4.5.3 to 4.6.0 and
89 packages to 88. It changes 55 package versions, adds `lintr`, `xml2`, and
`xmlparsedata`, and removes `lazyeval`, `pryr`, `stringi`, and `stringr`.
Goal 001 tests compatibility and invariants; it does not claim pre-refresh
output equivalence.

## Fresh Goal 001 Evidence (2026-07-11)

Goal 001 revalidated the inherited readiness patch on host R 4.6.1 against the
R 4.6.0 lock and `renv` 1.2.3. `renv::status()` reported the project
synchronized. The complete final engineering ladder passed:

- `make test`: 1,189 passed, 32 expected skips, zero failures or warnings;
- `make test-memory`: the retained-heap `lobstr` test passed with
  `NOT_CRAN=true`;
- `make lint`: zero diagnostics;
- `make smoke`: passed (`28` rebuilt, `18` current after replay-generated file
  timestamps changed);
- `make check`: zero errors, zero warnings, and the two established notes
  (`New submission`; non-standard top-level research-workflow files);
- `actionlint`: zero diagnostics;
- `git diff --check`: zero diagnostics after normalizing generated
  `renv/activate.R` trailing whitespace.

A separate source tarball was built and checked outside the checkout at
`/tmp/herbivoreTTR-standalone-final13.GqIlqG`. Its package tests reported 1,158
passes, 38 intentional skips, and zero warnings. The outer check reported only
the same two accepted notes:

```text
Maintainer: ‘Barry Brook <barry.brook@utas.edu.au>’

New submission
Non-standard files/directories found at top level:
  ‘_targets.R’ ‘AGENTS.md’ ‘CHANGELOG.md’ ‘config’ ‘Makefile’
  ‘metadata’ ‘portal’ ‘profiles’ ‘reports’ ‘scripts’
```

Fresh generated evidence:

- `artefacts/reports_v2/paper_pipeline_v2.html`: 45,785 bytes with every
  required scientific section present;
- `artefacts/reports_v2/figure_table_manifest_v2.csv`: its one artefact path,
  MD5 checksum, and byte count all match;
- release `v2.0.0-rc1-goal001-20260711-attempt6`: all 7 checklist rows pass,
  including substantive report and copied-manifest integrity, and the source tarball is 278,821
  bytes;
- v1 replay attempt 7: all 3 stages pass with an isolated library and fresh
  targets store;
- v2 replay attempt 6: all 5 stages pass, including a post-target phase boundary, post-suite report rendering
  and verification;
- both replay manifests record R 4.6.1, the exact R executable and R home,
  isolated libraries, fresh targets stores, pre-run snapshots, same-tree
  markers, and `all_pass: true`.

An independent review caught that the earlier checksum-valid v2 HTML had been
executed from `reports/` and therefore showed missing-section placeholders.
The renderer now sets Quarto's execution directory to the repository root, the
release checklist rejects placeholder reports, and the v2 replay rerenders and
verifies report content after its scientific suites.

A second independent review caught three control-surface weaknesses: weekly CI
uploaded a retired fixed replay path, malformed report manifests could pass
empty-vector checks, and duplicate basenames could produce ambiguous artefact
IDs. Focused red-green tests now bind weekly execution and upload to one named
fresh directory, require the complete manifest schema plus matching files and
hashes, and reject duplicate IDs during both writing and comparison. The active
pipeline and v1 reproducibility guides now document fresh sibling output,
library, and targets-store paths.

The original v1 replay path is retained as failed diagnostic evidence. Its
restore and 46-target fresh run passed, but verification exposed a stale-file
assumption: the targets graph owns `herb_day*.csv`, whereas
`herbivore_daily.csv` is produced by the separate scenario-runner pathway.
The corrected verifier checks every fresh semicolon-delimited herbivore
snapshot for finite mass and balances plus non-negative mass. Independent
review found this consistent with the existing output contract and not a new
ecological assumption.

Structured output review passed for two plant snapshots (800 rows), two
herbivore snapshots, all Experiment A v2 claims, and all Experiment C v2
claims: two supported and one optional `not_supported`. The stability table,
pilot benchmark, and scaling table also passed.

The May hashes are comparison context, not an output-equivalence baseline. The
release suite uses Experiment A `n = 30`, Experiment C `n = 20`, and four
120-day stability runs; the bounded replay uses six A/C seeds and three 90-day
stability runs. Experiment C therefore has one `supported`, one
`not_supported`, and one `partially_supported` claim in the release profile,
versus two `supported` and one optional `not_supported` claim in the replay.
The optional intake-drop values straddle machine zero. No threshold,
scientific rule, or required-claim result changed.

The ignored final replay manifest revalidated 44 hashes, sizes, and UTC
modification times. All 14 suite-owned outputs, including the substantive
45,785-byte replay report and its checksum manifest, are newer than the
post-target marker; all four target-owned snapshots are newer than the overall
v2 marker. The accepted 45,811-byte release report is also substantive. The
inspected files are therefore attributable to their named runs rather than a
later smoke run.

No scientific model assumptions, package version, public output schema, or CI
R 4.5.3 compatibility pin changed. This evidence supports a local R 4.6.x Mac
readiness baseline; it does not publish or tag a release.
