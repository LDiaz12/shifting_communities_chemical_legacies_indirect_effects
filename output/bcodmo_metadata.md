# BCO-DMO Dataset Metadata
## Shifting Communities and Chemical Legacies: Indirect Effects on Coral Physiology

**Submission files**

| File | Rows | Columns | Unit of observation |
|---|---|---|---|
| `bcodmo_coral_physiology.csv` | 96 | 11 | Individual coral fragment |
| `bcodmo_carbonate_chemistry.csv` | 690 | 27 | Tank × date × time point |

---

## 1. Study Overview

Mesocosm experiment conducted at the Richard B. Gump South Pacific Research Station, Moorea, French Polynesia (17.49°S, 149.83°W) during June 2024. Sixteen flow-through mesocosm tanks were assembled with one of four benthic community treatments mimicking distinct reef states observed on the Moorea backreef (LTER1 long-term monitoring site). *Acropora* sp. coral fragments were placed into tanks and exposed to community-conditioned water chemistry for the duration of the experiment. The study tests the causal pathway from community net community production (NCP) to coral physiology via pH and dissolved organic carbon.

**Temporal coverage:** 2024-06-02 to 2024-06-26

**Spatial coverage:** Moorea, French Polynesia (17.49°S, 149.83°W)

---

## 2. Experimental Design

Sixteen flow-through mesocosm tanks (n = 4 tanks per treatment) received one of four community treatments:

| Treatment code | Description |
|---|---|
| `Control` | No benthic community (seawater only) |
| `Algae_Dom` | Macroalgae-dominated community |
| `Coral_Dom` | Coral-dominated community |
| `Rubble_Dom` | Crustose coralline algae (CCA) / rubble-dominated community |

Each tank housed 6 *Acropora* sp. coral fragments drawn from 24 distinct genotypes (one fragment per genotype per treatment). Tank volume: 10 L. Benthic tile footprint: 22.5 × 22.5 cm (506.25 cm²). Flow-through seawater from two inflow tables (1 and 2) delivered unmodified ambient seawater; residence time and metabolic flux calculations are referenced against simultaneous inflow measurements.

---

## 3. Data Quality and Outlier Handling

### Coral physiology
One outlier rule was applied prior to export:

- **`mean_tissue_biomass`:** Values > 30 mg cm⁻² were set to `NA`. This threshold corresponds to biologically implausible tissue biomass values likely caused by retained skeleton or mucus during homogenisation (11 observations affected).

### Carbonate chemistry
Outliers were identified and set to `NA` using Tukey outer fences (IQR × 3) applied across all observations within each time-point block (noon and 9 PM treated separately; fences computed pooled across all tanks and treatments). No treatment-specific rules were applied.

Variables subject to outlier removal, by time block:

| Time block | Variables |
|---|---|
| Noon (12:00) | `DOC`, `NEC`, `NEP`, `pH`, `TA` |
| 9 PM (21:00) | `DOC`, `NEC`, `NEP`, `TA` |
| Other time points | None |

Observations with no measurement (e.g., DOC not collected at every time point) are also represented as `NA` and are distinct from outlier-removed values. The `Notes` column records field QC annotations that may help distinguish instrument errors from genuine missing data.

---

## 4. Parameter Descriptions

### 4.1 `bcodmo_coral_physiology.csv`

| Parameter | Description | Units | Type | Notes |
|---|---|---|---|---|
| `CORAL_NUM` | Unique numeric identifier for each coral fragment | — | integer | Primary key; 1–96 |
| `GENOTYPE` | Coral genotype code; each of 24 genotypes contributed one fragment per treatment | — | character | Single letter or alphanumeric code |
| `TREATMENT` | Benthic community treatment assigned to the tank housing the fragment | — | character | One of: Control, Algae_Dom, Coral_Dom, Rubble_Dom |
| `TANK_NUM` | Mesocosm tank identifier | — | integer | 1–16; 4 tanks per treatment |
| `endo_per_cm2` | Endosymbiont (Symbiodiniaceae) cell density per unit coral surface area | cells cm⁻² | numeric | Measured by haemocytometer following tissue airbrushing |
| `chla_ug_cm2` | Chlorophyll-a concentration per unit coral surface area | µg cm⁻² | numeric | Spectrophotometric measurement on acetone extract |
| `mean_tissue_biomass` | Ash-free dry weight of coral tissue per unit surface area | mg cm⁻² | numeric | Values > 30 mg cm⁻² set to NA (see §3) |
| `GP` | Gross photosynthesis rate | µmol O₂ cm⁻² h⁻¹ | numeric | Calculated as net photosynthesis + respiration from light and dark incubations |
| `R` | Respiration rate | µmol O₂ cm⁻² h⁻¹ | numeric | Dark incubation oxygen consumption |
| `pH_mean` | Mean daytime (noon) in-situ pH (total scale) in the fragment's assigned tank, averaged across all sampling dates | pH total scale | numeric | Derived from `bcodmo_carbonate_chemistry.csv`; used as path model predictor |
| `DOC_mean` | Mean daytime (noon) dissolved organic carbon concentration in the fragment's assigned tank, averaged across all sampling dates | µmol L⁻¹ | numeric | Derived from `bcodmo_carbonate_chemistry.csv`; used as path model predictor |

Missing value indicator: `NA`

---

### 4.2 `bcodmo_carbonate_chemistry.csv`

#### Identifiers and time

| Parameter | Description | Units | Type | Notes |
|---|---|---|---|---|
| `DATE` | Sampling date | YYYY-MM-DD | character | ISO 8601 format |
| `TIME` | Sampling time (local) | HH:MM:SS | character | Principal sampling times: 12:00 (noon) and 21:00 (9 PM); additional diel time points at 00:00, 06:00, 09:00, 14:00, 15:00, 18:00 |
| `DATETIME` | Combined date and time | ISO 8601 UTC | POSIXct | `YYYY-MM-DD HH:MM:SS` |
| `TANK_NUM` | Mesocosm tank identifier | — | integer | 1–16; NA for inflow measurements excluded from this file |
| `TREATMENT` | Benthic community treatment | — | character | One of: Control, Algae_Dom, Coral_Dom, Rubble_Dom |

#### Environmental conditions

| Parameter | Description | Units | Type | Notes |
|---|---|---|---|---|
| `TEMPINSITU` | In-situ seawater temperature at time of sampling | °C | numeric | Measured with submersible probe |
| `TEMPINLAB` | Temperature of sample at time of laboratory pH measurement | °C | numeric | Used for pH electrode calibration and temperature correction |
| `SALINITY` | Practical salinity of tank water | PSU | numeric | Measured with refractometer |

#### Hydraulics

| Parameter | Description | Units | Type | Notes |
|---|---|---|---|---|
| `FLOW_LEFT` | Left-side inflow rate | mL min⁻¹ | numeric | |
| `FLOW_RIGHT` | Right-side inflow rate | mL min⁻¹ | numeric | |
| `residence_time` | Hydraulic residence time of tank water | h | numeric | Calculated as tank volume (10,000 mL) ÷ total flow (mL min⁻¹) ÷ 60 |
| `flowrate` | Total inflow rate (FLOW_LEFT + FLOW_RIGHT) | mL min⁻¹ | numeric | |

#### Carbonate chemistry (measured and calculated)

| Parameter | Description | Units | Type | Notes |
|---|---|---|---|---|
| `TA` | Total alkalinity of tank outflow | µmol kg⁻¹ | numeric | Measured by open-cell potentiometric titration |
| `pH` | In-situ pH of tank outflow (total scale) | — | numeric | Calculated from spectrophotometric electrode mV via Tris calibration; corrected from lab temperature to in-situ temperature using `seacarb::pHinsi()` (ALK = 2200 µmol kg⁻¹, k1k2 = "m10", kf = "dg") |
| `DIC_umol_kg` | Dissolved inorganic carbon of tank outflow | µmol kg⁻¹ | numeric | Calculated from pH + TA using `seacarb::carb()` (flag = 8, k1k2 = "m10", kf = "dg", pHscale = "T") |
| `DOC` | Dissolved organic carbon (as non-purgeable organic carbon) of tank outflow | µmol L⁻¹ | numeric | Measured by high-temperature catalytic oxidation (Shimadzu TOC-L); converted from mg L⁻¹ assuming molecular weight of 12 g mol⁻¹ C |

#### Inflow reference values

| Parameter | Description | Units | Type | Notes |
|---|---|---|---|---|
| `pH_inflow` | In-situ pH of inflow water at matching date and time | — | numeric | Same calculation method as `pH`; drawn from Inflow1 or Inflow2 depending on tank's inflow table assignment |
| `TA_inflow` | Total alkalinity of inflow water | µmol kg⁻¹ | numeric | |
| `DIC_inflow` | Dissolved inorganic carbon of inflow water | µmol kg⁻¹ | numeric | |
| `DOC_inflow` | Dissolved organic carbon of inflow water | µmol L⁻¹ | numeric | |

#### Delta values (tank minus or inflow minus outflow)

| Parameter | Description | Units | Type | Notes |
|---|---|---|---|---|
| `deltapH` | pH of tank outflow minus pH of inflow | — | numeric | Positive = tank pH elevated above inflow |
| `deltaTA` | TA of inflow minus TA of outflow | µmol kg⁻¹ | numeric | Positive = net community uptake of alkalinity (calcification) |
| `deltaDIC` | DIC of inflow minus DIC of outflow | µmol kg⁻¹ | numeric | Positive = net community uptake of DIC (photosynthesis + calcification) |
| `deltaDOC` | DOC of tank outflow minus DOC of inflow | µmol L⁻¹ | numeric | Positive = net community release of dissolved organic carbon |

#### Community metabolic fluxes

| Parameter | Description | Units | Type | Notes |
|---|---|---|---|---|
| `NEC` | Net ecosystem calcification | mmol CaCO₃ m⁻² h⁻¹ | numeric | Alkalinity anomaly method: `(deltaTA / 2) × 1.025 × 10 × (1 / residence_time) × (1 / 506.25 cm²)`; positive = net calcification; factor of 2 for 2:1 TA:CaCO₃ stoichiometry; 1.025 kg L⁻¹ seawater density |
| `NEP` | Net ecosystem production | mmol C m⁻² h⁻¹ | numeric | DIC anomaly method: `(deltaDIC × 1.025 × 10 × (1 / residence_time) × (1 / 506.25 cm²)) - NEC`; positive = net autotrophy; NEC term removed to isolate organic carbon flux |

#### Quality control

| Parameter | Description | Units | Type | Notes |
|---|---|---|---|---|
| `Notes` | Field and laboratory quality-control annotations | — | character | Free text; includes instrument flags (e.g., flow read anomalies); NA when no annotation recorded |

Missing value indicator: `NA`

---

## 5. Derived Variable Methods Summary

### pH calculation
Per-calibration-date linear regression of Tris buffer mV vs. temperature (NIST-traceable Tris buffer; `mVTris ~ TTris`) interpolates the expected Tris buffer voltage at each sample's laboratory temperature. Electrode mV is converted to pH using `seacarb::pH()`. The resulting lab-temperature pH is then corrected to in-situ seawater temperature using `seacarb::pHinsi()` with a fixed alkalinity estimate of 2200 µmol kg⁻¹ (sufficient for temperature correction only). Equilibrium constants: Mehrbach et al. (1973) refitted by Dickson & Millero (1987) for K₁ and K₂ (`k1k2 = "m10"`); Dickson & Riley (1979) for KF (`kf = "dg"`).

### DIC calculation
Dissolved inorganic carbon is calculated from the co-measured pH and TA pair using `seacarb::carb()` with flag = 8 (pH + TA as inputs). Same equilibrium constants as above. TA is provided in µmol kg⁻¹ (converted internally to mol kg⁻¹).

### NEC and NEP
Metabolic fluxes are calculated from the difference between inflow and outflow chemistry, scaled by hydraulic residence time and benthic surface area (22.5 × 22.5 cm tile footprint = 506.25 cm²). Seawater density assumed at 1.025 kg L⁻¹. Tank volume: 10 L.

---

*Metadata prepared: 2026-06-02. Contact PI for questions regarding data collection protocols.*
