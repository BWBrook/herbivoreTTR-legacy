# Nightly CI restore fix

Date: 2026-04-27

## Context

The scheduled `Nightly Deep Checks` workflow failed on 2026-04-25 and 2026-04-26 at `r-lib/actions/setup-renv@v2`, before package tests, smoke targets, deep suites, or report rendering ran.

## Diagnosis

The failing runs used R 4.6.0 after the GitHub runner/action default advanced from R 4.5.3. The lockfile records R 4.5.3, so this default-version drift changed the renv cache key and forced a cold source restore. During that restore, `Rcpp` 1.1.0 failed to compile under R 4.6.0 with:

```text
fatal error: R_ext/PrtUtil.h: No such file or directory
```

The same workflow on the same commit succeeded on 2026-04-24 with R 4.5.3 and an existing renv cache.

## Change

- Pinned `Nightly Deep Checks` to R 4.5.3 to match `renv.lock`.
- Replaced the runtime GLPK package with development system dependencies already required by a cold renv restore: `libcurl4-openssl-dev` and `libglpk-dev`.

## Verification

Local verification was limited to workflow inspection because the failing behavior occurs inside GitHub-hosted Actions images and renv cache state. The relevant remote evidence was inspected with `gh run view` and job logs for runs `24949253426`, `24923236912`, and successful comparator run `24873901621`.

## Follow-up

After the nightly patch was pushed, the manual `Nightly Deep Checks` run `24979273993` passed on commit `e7da1cd`. The push-triggered `CI PR` workflow for the same commit failed because its matrix jobs still used the implicit R version and old runtime-only GLPK dependency. Logs for run `24979269220` showed the same R 4.6.0 cold-restore `Rcpp` failure. The same R 4.5.3 pin and cold-cache system dependency fix was therefore applied to `CI PR`.

The scheduled `Weekly Repro Check` run `24980179008` then failed on commit `6fc2595` at `setup-renv` for the same reason: `weekly_repro.yml` already had the cold-cache system dependencies but still used the implicit R version, so the runner installed R 4.6.0 and missed the R 4.5.3 cache. The weekly workflow was pinned to R 4.5.3 as well.
