# Roadmap v3 - Performance and Runtime Hardening Queue (herbivoreTTR)

This roadmap continues from the completed `docs/roadmap_v2.md` queue and is focused on
runtime throughput hardening while preserving ecological behavior and reproducibility.

Primary goal:
Deliver materially faster simulation throughput on commodity multicore hardware without
introducing behavior drift or weakening domain sanity protections.

---

## 1) Opening contract (v3)

When the maintainer says **"Follow roadmap_v3"**, Codex must:

1. Select the **first unchecked** work package (WP) in the Priority Queue.
2. Complete that WP end-to-end:
   - code,
   - tests,
   - docs,
   - artefacts,
   - interpretation log.
3. Run required quality gates and Artefact Review Cycle checks.
4. Mark the completed WP checkbox as `[x]`.
5. Continue immediately to the next unchecked WP unless blocked.

Reordering rule:
Any queue change requires both:
- rationale in `docs/decisions.md`, and
- a dated entry in `docs/log/`.

---

## 2) Work Package Definition of Done (WP-DoD v3)

A WP is done only when all are true:

1. **Implementation**
   - Target behavior is implemented with minimal blast radius.
   - Public interfaces remain stable unless explicitly versioned and documented.

2. **Tests**
   - Unit tests cover changed logic and failure paths.
   - Regression tests pin prior behavior where optimization/refactor is involved.

3. **Documentation**
   - User/developer docs updated for runtime semantics, defaults, and caveats.
   - Non-trivial assumptions captured in `docs/decisions.md`.

4. **Artefact Review Cycle**
   - source package build completed,
   - targets smoke pipeline completed,
   - at least one canonical output bundle generated and inspected,
   - sanity checks logged (NaN/Inf, non-negative biomass, gut-capacity, energy/water plausibility).

5. **Evidence trail**
   - A dated log under `docs/log/` includes commands, outputs, interpretation,
     and comparison versus prior evidence when relevant.

---

## 3) Priority Queue (strict order)

### Line 3.3.x - Kernel throughput hardening
- [x] **WP-3.3.1 - Transport kernel hotspot reduction pass v1**
- [x] **WP-3.3.2 - Domain-sanity guardrail cost reduction without safety drift**
- [x] **WP-3.3.3 - Post-optimization break-even re-baseline + CI perf sentinel**

### Line 3.4.x - Optional compiled acceleration (feature-flagged)
- [x] **WP-3.4.1 - Candidate kernel selection + parity harness for compiled path**
- [x] **WP-3.4.2 - Rcpp prototype (opt-in) with strict output parity checks**
- [x] **WP-3.4.3 - Hardware-tier defaults + ecologist-facing runtime guidance**

---

## 4) Milestone gates

- **Milestone M3.3:** all `WP-3.3.x` complete
- **Milestone M3.4:** all `WP-3.4.x` complete

At each milestone:
1. local gates green (`test`, `lint`, `smoke`, `check`),
2. artefact/log evidence complete,
3. clean commit(s) pushed.

---

## 5) Detailed WP specifications

### WP-3.3.1 - Transport kernel hotspot reduction pass v1

**Outcome**
- Reduce `transport_resistance()` runtime cost substantially while preserving ecological outputs.

**Why now**
- v2 hotspot artefacts identified repeated per-row data-frame mutation and list/sapply overhead in the TTR daily kernel.

**Scope**
- In:
  - optimize `transport_resistance()` internals,
  - optimize tiny derivative helpers where safe,
  - add regression tests pinning canonical outputs.
- Out:
  - model equation changes,
  - new dependencies,
  - compiled-code introduction.

**Required implementation**
1. Replace repeated per-row data-frame mutation in `transport_resistance()` with local vector-state caching and single write-back.
2. Preserve all guardrail checks and equations exactly.
3. Replace avoidable `sapply(..., is.null)` checks in derivative helper functions with direct scalar checks.
4. Add regression test for canonical day-step output contract (fixed seed + small deterministic fixture).
5. Produce pre/post benchmark and profile artefacts with explicit comparison summary.

**Acceptance criteria**
- Regression test proves no behavior drift on canonical fixture.
- Profile shows reduced self-time share for `transport_resistance` versus pre-optimization benchmark set.
- Transport micro-benchmark median elapsed time improves materially (target >= 20% reduction).

**Required tests**
- Existing TTR tests pass.
- New regression test for canonical day-step output contract.

**Artefact evidence**
- `artefacts/benchmarks/kernel_hotspot_reduction_v1/`:
  - `baseline/transport_resistance_benchmark_pre_v1.csv`
  - `optimized/transport_resistance_benchmark_post_v1.csv`
  - `baseline/kernel_profile_pre_v1_by_self.csv`
  - `optimized/kernel_profile_post_v1_by_self.csv`
  - `kernel_hotspot_reduction_summary_v1.csv`
  - `kernel_hotspot_reduction_report_v1.md`

**Completion notes (2026-02-09)**
- Implemented and validated.

---

### WP-3.3.2 - Domain-sanity guardrail cost reduction without safety drift

**Outcome**
- Lower overhead in domain sanity checks for long runs while preserving all failure semantics.

**Scope**
- In: fast-path checks, reduced repeated scanning/allocations, equivalent error classes/messages.
- Out: weakening thresholds or removing checks.

**Acceptance criteria**
- All existing domain sanity test suites pass unchanged.
- Profiling shows lower combined time in sanity-check call stack.
- Failure payload compatibility preserved.

**Completion notes (2026-02-09)**
- Implemented and validated.

---

### WP-3.3.3 - Post-optimization break-even re-baseline + CI perf sentinel

**Outcome**
- Refresh break-even policy and add lightweight performance sentinel to catch severe regressions.

**Scope**
- In: rerun scaling profile with updated kernel, update break-even recommendations, add non-flaky CI sentinel threshold.
- Out: strict timing assertions prone to runner noise.

**Acceptance criteria**
- Updated break-even artefacts and summary committed.
- Sentinel test detects severe (>X%) regression on representative workload.

**Completion notes (2026-02-09)**
- Implemented and validated.

---

### WP-3.4.1 - Candidate kernel selection + parity harness for compiled path

**Outcome**
- Identify exactly which kernel fragments are suitable for optional compiled acceleration.

**Acceptance criteria**
- Candidate list ranked by hotspot share and implementation risk.
- Parity harness design documented and tested for at least one candidate.

**Completion notes (2026-02-09)**
- Implemented and validated.
- Candidate-ranking artefacts written under `artefacts/benchmarks/compiled_candidate_selection_v1/` with hotspot/risk ranking and parity harness outputs.

---

### WP-3.4.2 - Rcpp prototype (opt-in) with strict output parity checks

**Outcome**
- Optional compiled implementation behind feature flag for one kernel candidate.

**Acceptance criteria**
- Compiled path opt-in only; default remains pure R.
- Output parity checks pass on fixed-seed scenarios.
- Fallback to pure R works automatically if compiled path unavailable.

**Completion notes (2026-02-09)**
- Implemented and validated.
- Optional compiled resistance kernel is enabled via `HERBIVORETTR_USE_COMPILED_TTR=1` or option `herbivoreTTR.use_compiled_ttr=TRUE`, with automatic fallback and warning when unavailable.
- Fixed-seed scenario parity artefacts written under `artefacts/benchmarks/compiled_scenario_parity_v1/`.

---

### WP-3.4.3 - Hardware-tier defaults + ecologist-facing runtime guidance

**Outcome**
- Runtime defaults and guidance mapped to laptop/workstation/server tiers.

**Acceptance criteria**
- Documented recommended worker settings by tier.
- Portal docs include runtime guidance and trade-off explanations.

**Completion notes (2026-02-09)**
- Implemented and validated.
- Hardware-tier default helpers now map `laptop/workstation/server` to conservative worker caps and reserve-core defaults.
- Portal schema/docs/templates now include `execution.parallel.hardware_tier` guidance and explicit trade-off notes.

---

## 6) Assumptions and defaults

- Ecological semantics must not change during performance-only WPs.
- Determinism contract remains non-negotiable.
- CI performance checks should be robust to runner variance; use broad guardrails, not microsecond assertions.
