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
- During scientist-in-the-loop walkthroughs, record both the human question and the assistant's technical/ecological response in near-real time.

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

### QA002 - Scientist-in-the-loop walkthrough reboot
- Date: 2026-03-11
- Phase: Ecologist-facing sanity check
- Asked by: Barry Brook
- Context: The repo has been hardened and redesigned to the current interim state, and the next step is a systematic ecologist-led walkthrough with the assistant acting as technical chaperone.
- Question: How should we structure the human-testing phase so ecological interpretation, interface feedback, and model-logic questions are captured as durable project knowledge?
- Response summary: Use this file as the session log, keep the walkthrough anchored to the ecologist-facing portal/reporting flow, and capture each substantive question as a separate QA entry with evidence paths, interpretation, and follow-up actions.
- Evidence reviewed:
  - `docs/q_and_a_interpretation.md`
  - `portal/README.md`
  - `portal/plans/templates/laptop_safe_template.yaml`
  - `portal/plans/templates/sensitivity_template.yaml`
- Ecological interpretation: The review should privilege directional plausibility, interface clarity, and whether outputs support ecological reasoning rather than only software correctness.
- Technical interpretation: We should start from stable, reproducible portal entry points and inspect generated manifests, tables, and figures together so any issue can be traced back to code, contract, or display logic.
- Action items:
  - [ ] Run a baseline single-scenario portal workflow and inspect the generated report artefacts together.
  - [ ] Log each question and answer as a new QA entry below this section.
  - [ ] Promote any stable scientific conclusions into `docs/decisions.md`.
- Status: open
- Linked roadmap/work package: Scientist-in-the-loop interpretation pass

## Working Agreement For This Phase

- Barry drives the ecological walkthrough and asks questions from the user-facing side of the repo.
- Codex answers with technical and modelling context, then records the exchange here as a new QA entry.
- If a question exposes a bug, confusing output, missing annotation, or weak ecological framing, capture at least one concrete follow-up action.
- Keep evidence paths specific wherever possible, including report tables, figures, manifests, scenario YAMLs, and relevant R functions.

## Recommended First Pass For Human Testing

1. Run the baseline portal workflow:
   `Rscript portal/run_plan.R portal/plans/templates/laptop_safe_template.yaml`
2. Identify the newest run directory:
   `ls -dt artefacts/portal_runs/* | head -n 1`
3. Review the high-level outputs first:
   - `report.html`
   - `tables/ecological_acceptance_summary.csv`
   - `manifests/portal_run_manifest.json`
   - `figures/`
4. As you inspect those artefacts, ask any question that comes naturally:
   - what a metric means,
   - whether a directional response is ecologically sensible,
   - whether a figure or table is confusing,
   - whether an output is missing something you would expect as an ecologist.
5. Once the baseline pass feels coherent, move to:
   `Rscript portal/run_sensitivity.R portal/plans/templates/sensitivity_template.yaml`
6. Use the sensitivity run to probe ecological directionality:
   - does changing herbivore pressure move vegetation and intake metrics the way you expect,
   - are the comparison tables and plots legible enough to support interpretation,
   - are any summary labels misleading or too software-centric.

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
