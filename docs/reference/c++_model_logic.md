# Overview of Herbivore-Plant Model

1.  **Initialization:**
    * Sets up a virtual plot with a defined grid of plants (grasses, trees with different C3/C4 types).
    * Initializes the state of each plant (biomass pools, height, type, etc.).
    * Initializes the state of one or more herbivores (mass, type - grazer/browser/mixed, location, initial energy/water balance).
    * Sets up environmental conditions (likely simplified placeholders in the current code).

2.  **Daily Plant Growth:**
    * For *every* plant in the plot, *every* day:
        * It runs the Thornley Transport Resistance (TTR) model.
        * This simulates photosynthesis (carbon gain), nitrogen uptake, and water uptake (including stress effects).
        * It allocates the acquired C and N to different plant parts: leaves, stems, roots, defence structures, and reproductive structures, updating their biomass.

3.  **Daily Herbivore Actions (after spin-up period):**
    * For *every* herbivore, *every* day:
        * **Plant Selection:** The herbivore assesses nearby plants and selects one to target based on a 'utility' or 'tastiness' score. This score considers:
            * How well the plant's C:N ratio matches the herbivore's target C:N ratio.
            * The amount of defence biomass in the plant (less defence is better).
            * Distance to the plant (closer is better).
            * Suitability of the plant type for the herbivore type (e.g., grazer vs. grass).
            * Whether the plant is within the herbivore's browse height.
            * Includes randomness, so it's not purely deterministic.
        * **Movement:** The herbivore moves towards the selected plant, covering a certain distance. The plot wraps around (toroidal).
        * **Foraging/Intake:** The herbivore consumes biomass from the selected plant (if reached or close enough).
            * Intake is limited by handling time (increased by plant defence), gut capacity, and available biomass.
            * It calculates the amount of Dry Matter (DM), Carbon, Nitrogen, Protein Energy (PE), Non-Protein Energy (NPE), and water ingested.
            * It updates the plant's biomass accordingly.
        * **Updating Balances:** The herbivore's internal energy balance (kJ) and water balance (kg) are updated based on intake. Gut fullness is tracked.
        * **Calculating Costs:** Daily costs are calculated and deducted from the energy/water balance:
            * Basal Metabolic Rate (BMR).
            * Activity cost (based on distance moved).
            * Thermoregulation cost.

4.  **Output:**
    * Writes the state of every plant (biomass pools, height, etc.) to `plants.txt` each day.
    * Writes the state of every herbivore (location, mass, daily intake totals, distance moved, energy/water balance) to `herbivores.txt` each day.

**In essence, the simulation currently models:**

* The daily growth cycle of individual plants competing implicitly for resources via the TTR model.
* The daily foraging cycle of individual herbivores making sophisticated, nutritionally-driven choices about which plants to eat.
* The movement of herbivores across the landscape in response to those choices.
* The immediate impact of herbivory on plant biomass.
* The daily energy and water budget dynamics of the herbivores based on their intake and activity costs.

It simulates the *process* of foraging to meet nutritional targets and the associated costs, tracking the state changes in both plants and herbivores that result from these daily interactions. It does *not* yet simulate the longer-term consequences like herbivore growth, reproduction, death, or nutrient cycling through excretion.

# Summary of Logical Flow

This ecological simulation models the daily interactions between herbivore agents and plants within a spatially explicit, toroidal environment. Each daily simulation cycle follows these steps:

### Initialization:
- **Plants** are positioned on a grid with defined biomass and nutrient characteristics (shoot/root biomass, nitrogen, carbon, and defensive structures).
- **Herbivores** start each day with initialized gut content, gut capacity, mass, energetic and water balances, and behavioral states.

### Daily Simulation Logic:
1. **Plant Update**: Plants grow or respond according to environmental conditions, modifying their biomass and nutritional composition.
   
2. **Herbivore Daily Cycle**:
    - Reset daily variables (gut contents, water/energy balances, distances traveled).
    - Calculate key herbivore-specific traits from body mass (gut capacity, bite size, handling time, movement velocity).
    
3. **Minute-by-minute Foraging Simulation** (1,440 minutes/day):
    - Determine if the herbivore is currently **eating**, **moving**, or idle.
    - **If eating**:
        - Evaluate current plant's nutritional quality, biomass, and defenses.
        - Continue feeding if advantageous; otherwise, select a new plant target.
    - **If moving**:
        - Move toward the selected plant based on maximum velocity and update herbivore coordinates, considering toroidal world-wrapping.
        - Reevaluate plant choice periodically or when close enough to start feeding.
    - **Herbivory and Digestion**:
        - Herbivore takes bites of plants, consuming leaf, stem, and defensive tissues.
        - Plant biomass and nutrient pools are updated accordingly.
        - Digestion tracked hourly, nutrients gradually moved through the gut and assimilated into energy/water balances or excreted.
        
4. **Energetic and Hydrological Balance**:
    - Hourly updates incorporate digestible carbohydrates/proteins, adjust energy balances, and produce metabolic water.
    - At day’s end, check water balance; if insufficient, the herbivore must move to water, incurring a locomotion cost.
    - Death occurs if energy or water balances stay critically low for too long (not yet fully implemented).

### Daily Output:
- Biomass, nutrient status of plants, and herbivore movement, energetic status, and water balance are logged daily.

---
# Detailed Pseudocode

## Part 1: Daily Initialization and Herbivore Setup

**FUNCTION: Daily_Simulation_Run (Plants, Herbivores, Environment, day)**

Begin daily simulation for day `day`:

Initialize or reset daily variables for each herbivore:

For each `Herbivore` in `Herbivores`:
  - Reset `gut_content` to 0
  - Reset daily intake metrics (`intake_defence_day`, `intake_digest_carbohydrate_day`, `intake_digest_protein_day`, etc.) to 0
  - Reset daily water intake metrics to 0
  - Reset daily distance traveled to 0
  - Calculate herbivore-specific traits based on `mass`:
    - `gut_capacity` ← scaling relationship (`mass`)
    - `bite_size` ← scaling relationship (`mass`)
    - `handling_time` ← scaling relationship (`mass`)
    - `foraging_velocity_max` ← scaling relationship (`mass`)
  - Initialize `current_hour`, `last_hour` variables (set to zero or previous day’s final state)

---

## Part 2: Minute-by-Minute Herbivore Foraging and Digestion

Loop through each minute of the day (minutes: 0 to 1439):

- Update `minute_continuous` (cumulative across simulation days)
- Update `last_hour` to `current_hour`
- Compute `current_hour` as `floor(minute_continuous / 60)`

IF (`current_hour` ≠ `last_hour`):
  - Call FUNCTION `Incorporate_Energy(Herbivore)`
  - Call FUNCTION `Digest_and_Excrete(Herbivore)`
  - Update `gut_content` as sum of biomass in digestion vectors

IF (`minute` < daily foraging limit in minutes):
  - IF herbivore gut has space (`gut_content` < `gut_capacity`):
    - Calculate required DP:DC ratio for optimal nutrition (`calc_required_energy_ratio`)
    - IF herbivore behavior = EATING:
        - IF current plant biomass sufficient:
            - Evaluate nutritional value (DP:DC ratio) relative to needs
            - Calculate local plant density to determine likelihood of continuing feeding
            - IF conditions favorable, CONTINUE EATING current plant:
                - Call FUNCTION `Eat(Herbivore, Current_Plant)`
            - ELSE select a new plant:
                - Set herbivore behavior to MOVING
                - Call FUNCTION `Pick_A_Plant(Herbivore)`
                - Call FUNCTION `Herbivore_Move(Herbivore)`
        - ELSE select new plant (biomass insufficient):
            - Set herbivore behavior to MOVING
            - Call FUNCTION `Pick_A_Plant(Herbivore)`
            - Call FUNCTION `Herbivore_Move(Herbivore)`
    - ELSE IF herbivore behavior = MOVING:
        - IF distance to selected plant ≤ EATING_RADIUS:
            - Set behavior to EATING
            - Call FUNCTION `Eat(Herbivore, Selected_Plant)`
        - ELSE:
            - Possibly select new target occasionally (stochastic)
            - Call FUNCTION `Herbivore_Move(Herbivore)`
- ELSE (beyond daily foraging limit):
  - Herbivore rests or idle (no explicit behavior yet)

---

## Part 3: Detailed Herbivore Foraging, Energy & Water Dynamics

Continue the minute-by-minute loop for each herbivore:

After daily foraging minutes completed:

- Calculate daily **water requirements** based on herbivore mass (`calc_water_requirement`):
  - IF total daily water intake from metabolic processes (`metabolic_water_day`) + forage water (`intake_water_forage`) < daily water requirement:
    - Herbivore must move to water source:
      - Increment `distance_moved` by fixed distance to water (`DIST_TO_WATER`)
      - `intake_water_drinking` ← difference to meet requirement

- Calculate **energy balance** for the day:
  - `energy_balance` incremented by:
    ```
    total daily energy intake (PE_day + NPE_day) - [maintenance cost + locomotion cost]
    ```
  - Maintenance cost ← scaling relationship (`mass`)
  - Locomotion cost ← scaling relationship (`mass`, `distance_moved`)

- Calculate **water balance**:
  ```
  water balance += (metabolic_water_day + intake_water_forage + intake_water_drinking) - daily_water_requirement
  ```

---

## Part 4: Plant Selection and Movement Functions

**FUNCTION: Pick_A_Plant (Herbivore, Plants):**

- Determine plants within herbivore’s detection radius (`DETECTION_DISTANCE`):
  - Convert herbivore coordinates to bucket/index space (for efficiency)
  - Identify plants within radius:
    - IF plants exist:
      - Calculate “tastiness” score for each plant based on:
        - Nutritional ratio difference (herbivore needs vs. plant N:C)
        - Defensive biomass (high defense = lower tastiness)
        - Distance (further away = less attractive)
      - Convert tastiness scores to weighted probabilities
      - Randomly select a plant according to probabilities
      - IF no plants appealing (zero probability):
        - Choose a random coordinate as a target point instead
    - ELSE (no plants found):
      - Choose random coordinate as target point
- Update herbivore’s `selected_plant_ID` and `selected_plant_dist`

**FUNCTION: Herbivore_Move (Herbivore, Plants):**

- Calculate maximum possible distance moved this timestep (`FV_max` * timestep duration)
- IF selected plant is within reach this timestep:
  - Move directly to plant; update herbivore coordinates to plant’s location
- ELSE:
  - Move partially towards the selected plant:
    - Calculate straight-line path and coordinates reachable this timestep
    - Implement world wrapping (torus) to ensure shortest possible distance around edges
- Increment `distance_moved`
- Update distance to target plant (if applicable)

---

## Part 5: Digestion, Excretion, and Biomass Interactions

**FUNCTION: Eat (Herbivore, Plant):**

- Calculate forage intake rate (kg dry matter/minute):
  ```
  veg_per_minute = (1 / handling_time / 1000) * (1 - proportion_defence)
  ```
  - Defence biomass (`bdef`) proportionally slows eating rate.
  
- Calculate actual intake (`intake_XDM`), taking the minimum of:
  - Available plant biomass (`plant.Ms - MIN_SHOOT`)
  - Maximum intake per minute (`veg_per_minute`)
  - Available gut capacity (`gut_capacity - gut_content`)

- Biomass breakdown from intake:
  - Allocate intake among `leaf`, `stem`, and `defence` proportional to their biomass fractions.
  - Calculate carbon (`C`) and nitrogen (`N`) intake based on biomass fractions.

- Update herbivore daily totals:
  - `intake_total_day` and running total `intake_total` incremented by intake.
  - Update daily defensive biomass intake (`intake_defence_day`).
  - Update forage water intake (`intake_water_forage`) based on plant water content.

- Update digestion tracking vectors at index `[0]`:
  - Biomass (`leaf`, `stem`, `defence`)
  - Digestible carbohydrates (`dc_leaf`, `dc_stem`)
  - Digestible proteins (`dp_leaf`, `dp_stem`, `dp_def`)

- Update plant biomass pools by removing eaten amounts:
  ```
  plant.bleaf -= intake_leaf
  plant.bstem -= intake_stem
  plant.bdef  -= intake_def
  plant.ms    -= (intake_leaf + intake_stem + intake_def)
  plant.qshoot -= intake_water
  ```

---

**FUNCTION: Incorporate_Energy (Herbivore):**

Each hour (when hour changes):

- Convert digestible carbohydrates and proteins from the gut (`Digestion_*` vectors) into usable energy:
  - Digestible carbs (`DC`) → Non-protein energy (`intake_NPE_day`)
  - Digestible proteins (`DP`) → Protein energy (`intake_PE_day`)
  
- Increment daily totals of digestible carbohydrates and proteins.

- Calculate metabolic water production from digesting protein and carbs:
  ```
  metabolic_water_day += CARB_TO_MW * intake_DC + PROTEIN_TO_MW * intake_DP
  ```

---

**FUNCTION: Digest_and_Excrete (Herbivore):**

Each hour:

- Shift gut contents one hour forward along digestive tract vectors (`Digestion_*`):
  - Biomass (`leaf`, `stem`, `defence`)
  - Digestible carbohydrates (`dc_*`)
  - Digestible proteins (`dp_*`)
- Final vector cells (end of digestion) represent excreted material—removed from system.

- Reset initial cells (`[0]`) of digestion vectors to zero, ready for next intake.

---

## Part 6: Initialization and Supporting Functions

**FUNCTION: init_plants()**

- Position plants in a grid, evenly spaced:
  ```
  for each plant (i):
    set xcor, ycor coordinates based on grid spacing
  ```

- Assign to each plant:
  - `VegType` randomly (grass/tree)
  - Initial biomass (`Ms` and `Mr`) randomly within realistic range
  - Carbon (`C`) and nitrogen (`N`) concentrations randomly
  - Calculate initial `Cs`, `Cr`, `Ns`, `Nr` from these concentrations

- Set biomass allocations based on type:
  - Trees (`VegType=2`): half biomass leaf, half stem, minor defence, height set
  - Grasses (`VegType=0,1`): almost all biomass leaf, minor defence, height set

- Initialize root and shoot water content proportionally:
  ```
  plant.QRoot, plant.QShoot proportional to root and shoot biomass
  ```

---

**FUNCTION: init_herbivore()**

- Assign initial herbivore properties:
  - Mass (`mass`) and herbivore type (`HerbType`)
  - Starting coordinates (`xcor`, `ycor`)
  - Digestive capacity parameters:
    - Gut retention time (`MRT`)
    - Initial gut contents (zeroed digestion vectors)
    - Behaviour initialized as `MOVING`

- Daily parameters reset:
  - Energy/water balances, intake totals, distances, etc.

---

**FUNCTION: init_conditions()**

- Generate 365 daily values for temperature, water, soil N:
  ```
  for each day (365):
    Conditions.Temp_mean_in = sinusoidal annual cycle
    Conditions.SW, Conditions.N = constants
  ```

---

**FUNCTION: LinearSpacedArray(start, end, N)**

- Generate N evenly spaced values from `start` to `end`.

---

**FUNCTION: main()**

- Initialization:
  - Call `init_conditions()`, `init_plants()`, `init_herbivore()`

- For each simulation day/year:
  - Update plant physiological state (via external function, e.g. `transport_resistance()`)
  - If herbivory active:
    - Call `herbivory_run()` for each herbivore
    - Update herbivore movements, feeding, digestion, and balances
  - Write output files daily (`plants.txt`, `herbivores.txt`, logs)

- End of simulation: Clean up memory and close outputs.
