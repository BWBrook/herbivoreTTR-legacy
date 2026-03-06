# Portal Human-Testing Q&A and Interpretation Log

## Purpose
This is the living record for human-guided portal testing.
It captures:
- ecological questions raised during walkthroughs,
- technical answers and evidence paths,
- interpretation notes,
- follow-up actions and decisions.

The goal is to preserve reasoning, not just outcomes, so we can convert insights into roadmap updates, tests, docs, and guardrails.

## Logging Rules
- Add one entry per distinct question or concern.
- Always include evidence paths (tables, figures, manifests, logs) used to answer the question.
- If a question reveals a bug, ambiguity, or missing guardrail, add a concrete action and owner.
- If a question changes scientific or workflow assumptions, mirror the final decision in `docs/decisions.md`.

## Entry Template
Copy this block and fill it in for each new question.

```md
### QAXXX - <short title>
- Date:
- Phase:
- Asked by:
- Context:
- Question:
- Response summary:
- Evidence reviewed:
  - <path>
  - <path>
- Ecological interpretation:
- Technical interpretation:
- Action items:
  - [ ] <action>
- Status: open | resolved | actioned
- Linked roadmap/work package:
```

## Current Session

### QA001 - Human-testing phase kickoff
- Date: 2026-02-09
- Phase: Portal guided walkthrough
- Asked by: PI
- Context: Transition from autonomous development to ecologist-led sanity checks.
- Question: How should we run the first structured portal checks?
- Response summary: Start with a conservative single-scenario profile, inspect acceptance tables and manifest context, then run sensitivity profile for directional ecological checks.
- Evidence reviewed:
  - `portal/README.md`
  - `portal/plans/templates/laptop_safe_template.yaml`
  - `portal/plans/templates/sensitivity_template.yaml`
- Ecological interpretation: The first pass should verify directional plausibility and acceptance summaries before exploring larger scenario contrasts.
- Technical interpretation: Begin with reproducible one-command templates and inspect generated artefacts under `artefacts/portal_runs/`.
- Action items:
  - [ ] Run the laptop-safe single scenario template and review acceptance outputs.
  - [ ] Run sensitivity template and inspect monotonic/directional responses.
  - [ ] Capture each question and interpretation in this document.
- Status: open
- Linked roadmap/work package: Post-3.5 portal hardening feedback loop

## Human-Testing Kickoff Checklist

1. Run a baseline single scenario:
   `Rscript portal/run_plan.R portal/plans/templates/laptop_safe_template.yaml`
2. Identify the most recent run directory:
   `ls -dt artefacts/portal_runs/* | head -n 1`
3. Inspect the ecological acceptance summary table:
   `cat <run_dir>/tables/ecological_acceptance_summary.csv`
4. Inspect execution context and fallback flags:
   `cat <run_dir>/manifests/portal_run_manifest.json`
5. Open and visually review generated figures in:
   `<run_dir>/figures/`
6. Run the sensitivity template:
   `Rscript portal/run_sensitivity.R portal/plans/templates/sensitivity_template.yaml`
7. Inspect sensitivity acceptance and comparison tables:
   `cat <run_dir>/tables/sensitivity_ecological_acceptance_summary.csv`

## Notes
- This file is intentionally incremental and may contain open questions.
- Resolved items should remain here for provenance.
