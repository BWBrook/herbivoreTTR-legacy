## 1) What TTR.PGM is optimized for (and what it actually exposes)

Package details here: https://cran.csiro.au/web/packages/TTR.PGM/
Paper: "TTR.PGM: An R package for modelling the distributions and dynamics of plants using the Thornley transport resistance plant growth model." 
https://besjournals.onlinelibrary.wiley.com/doi/10.1111/2041-210X.70071

From the CRAN docs/manual and package sources:

* **Purpose / positioning:** TTR.PGM is presented as an implementation of the Thornley transport resistance plant growth model that is meant to simulate plant growth **forced by climate system variables**, and it explicitly provides tooling for **formatting forcing variables, simulating growth dynamics, and calibrating parameters**.
* **Model inputs / drivers:** `get_input()` expects time‑varying matrices for temperatures (tcur/tnur/tgrowth/tloss), and can use shortwave radiation + CO₂ to calculate photosynthesis (via `calc_photo()`), and can compute a soil water content index if you supply precipitation + PET + wilting point + field capacity (via `make_swc()`).
* **Output structure:** `run_ttr()` returns a **4‑D array** indexed by `(output variable, species, time, site)` and the docs note **“Currently only one species is supported.”**
* **Orientation toward inference / SDM / time series:** The paper (as described in accessible materials) emphasizes process‑based modelling for distributions and demonstrates applications like **species distribution modelling using occurrence data** and **time series vegetation activity (SIF) analyses**.
* **Implementation/ops reality:** It’s a compiled package (Rcpp/RcppArmadillo; CXX17) and licensed **LGPL‑3**.

**Net:** TTR.PGM is a **climate‑forced, inference‑friendly, C++ process model toolkit** that is designed around “many timesteps × many sites” workflows (and model fitting).

## 2) What your current repo’s TTR implementation is optimized for

Your in‑repo implementation is clearly shaped around the coupling problem:

* **State is per‑plant individual and mutable.** `init_plants()` builds a per‑plant state table with shoot/root structural mass and C/N substrate pools (`ms/mr/cs/cr/ns/nr`), plus explicit structural pools (`bleaf/bstem/broot`), height, water content (`qroot/qshoot`), and transport resistances/flux bookkeeping (`rsC/rrC/...`, `tauC/tauN/...`).
* **Multiple plant “veg types” are first‑class.** You explicitly support `veg_type` ∈ {C3 grass, C4 grass, tree}, and you already have leaf/stem splits for trees (and leaf-only for grasses), which is essential for grazer/browser diet access.
* **Daily stepping is already integrated with the herbivore loop.** `ttr_daily()` is structured as “update each plant once per day given forcing variables + current internal state”, which is exactly what you need if herbivores remove biomass during the day and you reconcile growth at the day boundary.

**Net:** Your in‑repo TTR is a **coupling‑first, individual‑mutable, multi‑PFT plant engine**. It’s not just “a TTR solver”; it’s a plant state backend designed to be poked by herbivory.

## 3) Key mismatches if you “switch fully” to TTR.PGM (Option ii)

These are the big reasons a full switch is risky **for your specific project**:

### A) Species / functional type support mismatch

TTR.PGM’s own docs say: **“Currently only one species is supported.”**
Your model’s value proposition includes simultaneous grazers/browsers/mixed feeders selecting among **multiple plant functional types** (and likely multiple “plant individuals” of different types in one landscape). Full replacement would either:

* force you into a **single plant type per run** (breaking the ecology), or
* require you to emulate multiple plant types by re‑running TTR.PGM multiple times and stitching results (expensive and conceptually awkward), or
* require deeper modifications to TTR.PGM internals (not realistic for this project).

### B) Interface mismatch: “run whole timeseries” vs “step‑and‑mutate”

TTR.PGM is built around formatting forcing matrices and calling `run_ttr()` to simulate an entire series returning a 4‑D array.
Your coupling needs the opposite: herbivores **change plant state** (e.g., leaf/stem biomass, potentially N content) between timesteps, and the plant model must accept those mutations cleanly. You *can* wrap TTR.PGM to do single‑step runs, but you quickly run into:

* overhead and complexity building the required `Data` object repeatedly,
* ambiguity about how to represent **per‑individual heterogeneous initial conditions** (TTR.PGM workflows often treat initial mass as a parameter to estimate; in examples it’s a per‑species parameter),
* uncertainty about mapping your extended plant state (leaf/stem/height/water/defence) into TTR.PGM’s state variables.

### C) Structural pools and browsing/grazing realism

TTR.PGM’s focus is on plant growth/transport dynamics and climate forcing; your model *needs* explicit **edible compartments** (leaf vs stem) because browsers and grazers differ in what they can access. Your implementation already carries those pools; switching fully would likely force you to re‑implement a lot of the “ecology interface layer” anyway.

### D) Scope creep risk

TTR.PGM includes calibration and statistical model scaffolding; that’s valuable, but it’s not your core objective.
Full adoption tends to pull the project toward “SDM / inference workflows” rather than “herbivore–vegetation interaction simulator”.

## 4) Benefits you’d lose if you ignore TTR.PGM (Option i only)

There *are* real upsides to TTR.PGM you shouldn’t throw away:

* **Scientific credibility / provenance:** it’s a published, CRAN‑distributed implementation with tested, compiled code.
* **Climate forcing realism:** built‑in photosynthesis modelling (`calc_photo`) and soil water indexing (`make_swc`) are useful and widely reusable.
* **A natural benchmark/reference:** it gives you a “known implementation” to sanity‑check your own solver in overlapping regimes.

## 5) My recommendation: **Option iii (Hybrid), with a very specific split of responsibilities**

### Decision

**Do a hybrid** where:

1. **Your in‑repo TTR remains the default plant engine for the coupled herbivore simulation.**
2. **TTR.PGM becomes an optional backend + validation benchmark**, not a wholesale replacement.

### Why this is the best move

* It preserves what makes your project novel and functional: **individual‑based coupling, multi‑PFT vegetation, and edible compartment realism**.
* It captures what TTR.PGM is best at: **a vetted, climate‑forced TTR implementation** and **tooling for forcing and calibration**.
* It avoids the biggest blocker: **single‑species limitation** in TTR.PGM, which is a show‑stopper for full replacement right now.

### What “hybrid” means concretely

I’d implement it (at the architecture level) like this:

**A) Define a stable internal “Plant backend interface”**
A small set of functions your herbivore simulator calls, e.g.:

* `plant_backend_init(params, layout, seed) -> plant_state`
* `plant_backend_step_day(plant_state, env_day, dt=1 day) -> plant_state`
* `plant_backend_apply_herbivory(plant_state, removals) -> plant_state`
* `plant_backend_observe(plant_state) -> plant_metrics` (leaf/stem availability, N content, water, etc.)

**B) Provide two backends**

* **Backend 1 (default):** your current R implementation (fastest path to a working coupled model).
* **Backend 2 (optional):** a `TTR.PGM` adapter, explicitly documented as:

  * best for **single‑species / single‑PFT** scenarios,
  * best for **benchmarking/validation**, and potentially plant-only workflows.

**C) Use TTR.PGM for regression sanity checks**
Create a tiny “overlap test suite” that runs only if `TTR.PGM` is installed (Suggests), comparing:

* mass trajectories under a simple forcing regime,
* qualitative invariants (non-negative masses, reasonable monotonicity under high forcing),
* numerical closeness under matched parameters (within tolerance).

This gives you *scientific guardrails* without forcing the whole project into TTR.PGM’s API constraints.

### Licensing note (important but not scary)

TTR.PGM is **LGPL‑3**.
That’s compatible with using it as an **external dependency** (i.e., you call its functions; you don’t copy its code). Your package can remain MIT as long as you’re not incorporating LGPL code into your own source base. Practically: **don’t copy/paste their implementation**; wrap it.

## 6) Practical “go-forward” guidance (what I’d do next)

1. **Lock the decision in writing** (repo decision record):
   “Default: internal TTR backend; optional: TTR.PGM backend for validation and single‑species mode.”

2. **Short proof-of-fit spike (1–2 days of engineering time, not weeks):**

   * Can we represent each plant as a “site” in TTR.PGM and run one daily timestep?
   * If not cleanly possible, keep TTR.PGM strictly as an *external benchmark* and drop the idea of using it as a live backend until it supports multi-species/per-site initial states.

3. **Benchmark your implementation against TTR.PGM in the simplest overlap case**

   * single plant, no herbivory, daily forcing,
   * compare `Ms/Mr/Cs/Cr/Ns/Nr` (or the closest equivalents).

4. **Only revisit “full switch” if/when** TTR.PGM supports multi-species (or parameter‑by‑site in a way that lets you encode veg_type and per-individual states cleanly). Their docs explicitly say that isn’t the case today.

---

## Final call (what you should do)

**Choose (iii) hybrid.**

* **Do not** replace your plant engine wholesale with TTR.PGM right now; the “currently only one species” constraint and the timeseries/site‑oriented API make that a high‑risk detour for an individual‑based, multi‑PFT herbivore coupling project.
* **Do** incorporate TTR.PGM as:

  * an *optional* dependency for plant-only workflows / single‑PFT mode, and
  * the *reference implementation* you test against to keep your TTR math honest and defensible.

If you follow this, you get the best of both worlds: **your coupling-focused simulator stays on track**, and you still inherit the **credibility and tooling** of the new ecosystem package where it actually fits.
