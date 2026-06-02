library(tidyverse)
library(here)
library(seacarb)
library(lubridate)
library(broom)

# ══════════════════════════════════════════════════════════════════════════════
# BCO-DMO Export: Coral Physiology
# ══════════════════════════════════════════════════════════════════════════════
# Outlier rule (from path_analysis_report_robust.qmd, chunk load-metadata):
#   mean_tissue_biomass > 30 mg cm⁻² → NA
#   (biologically implausible; likely retained skeleton or mucus during
#    tissue homogenisation)

coral_physiology_bcodmo <- read_csv(
  here("data", "coral_physiology.csv"),
  show_col_types = FALSE
) |>
  mutate(
    TREATMENT = factor(
      TREATMENT,
      levels = c("Control", "Algae_Dom", "Coral_Dom", "Rubble_Dom")
    ),
    mean_tissue_biomass = ifelse(mean_tissue_biomass > 30, NA_real_, mean_tissue_biomass)
  ) |>
  # Explicit column order: identifiers first, then physiology measurements,
  # then tank-level chemistry summaries used in path analysis
  dplyr::select(
    CORAL_NUM, GENOTYPE, TREATMENT, TANK_NUM,
    endo_per_cm2, chla_ug_cm2, mean_tissue_biomass,
    GP, R,
    pH_mean, DOC_mean
  )

write_csv(coral_physiology_bcodmo, here("output", "bcodmo_coral_physiology.csv"))

cat("coral_physiology: ", nrow(coral_physiology_bcodmo), "rows,",
    ncol(coral_physiology_bcodmo), "cols\n")
cat("  mean_tissue_biomass NAs (outliers set to NA):",
    sum(is.na(coral_physiology_bcodmo$mean_tissue_biomass)), "\n\n")

# ══════════════════════════════════════════════════════════════════════════════
# BCO-DMO Export: Carbonate Chemistry
# ══════════════════════════════════════════════════════════════════════════════
# Reproduces the full processing pipeline from path_analysis_report_robust.qmd
# (chunks load-chem and outlier-removal).

# ── Load raw files ─────────────────────────────────────────────────────────────
pHcalib  <- read_csv(here("data", "tris_calibration.csv"),    show_col_types = FALSE)
pHData   <- read_csv(here("data", "carbonate_chemistry.csv"), show_col_types = FALSE)
TableID  <- read_csv(here("data", "tank_lookup.csv"),         show_col_types = FALSE)
DOC_data <- read_csv(here("data", "doc_tn_data.csv"),         show_col_types = FALSE)

# ── pH calculation ─────────────────────────────────────────────────────────────
# Per-calibration-date linear model of mV vs. temperature; Tris buffer voltage
# interpolated at each sample's lab temperature; seacarb::pH() converts
# electrode mV to pH (total scale); seacarb::pHinsi() corrects to in-situ temperature.
pHSlope <- pHcalib |>
  nest_by(TrisCalDate) |>
  mutate(fitpH = list(lm(mVTris ~ TTris, data = pHcalib))) |>
  reframe(broom::tidy(fitpH)) |>
  dplyr::select(TrisCalDate, term, estimate) |>
  pivot_wider(names_from = term, values_from = estimate) |>
  right_join(pHData, by = "TrisCalDate") |>
  mutate(mVTris = TEMPINLAB * TTris + `(Intercept)`) |>
  drop_na(TEMPINSITU, mV) |>
  mutate(pH = seacarb::pH(Ex = mV, Etris = mVTris, S = SALINITY, T = TEMPINLAB)) |>
  drop_na(TEMPINSITU, TEMPINLAB, SALINITY, pH) |>
  mutate(pH_insitu = seacarb::pHinsi(
    pH = pH, ALK = 2200, Tinsi = TEMPINSITU, Tlab = TEMPINLAB,
    S = SALINITY, Pt = 0.1, k1k2 = "m10", kf = "dg"
  )) |>
  dplyr::select(-pH) |>
  rename(pH = pH_insitu) |>
  ungroup() |>
  dplyr::select(-c(mV, TrisCalDate, TTris, `(Intercept)`, mVTris))

# ── DIC calculation ────────────────────────────────────────────────────────────
# flag = 8: pH (total scale) + TA constrain the carbonate system.
# k1k2 = "m10" (Mehrbach refitted Dickson & Millero), kf = "dg" (Dickson & Riley).
DIC_calc <- pHSlope |>
  drop_na(pH, TA) |>
  mutate(TA_mol_kg = TA / 1e6)

carb_table <- seacarb::carb(
  flag = 8, var1 = DIC_calc$pH, var2 = DIC_calc$TA_mol_kg,
  S = DIC_calc$SALINITY, T = DIC_calc$TEMPINSITU,
  P = 0, Patm = 0, Pt = 0, Sit = 0,
  pHscale = "T", kf = "dg", k1k2 = "m10", ks = "d"
)

DIC_calc <- DIC_calc |>
  bind_cols(carb_table |> dplyr::select(DIC) |> mutate(DIC_umol_kg = DIC * 1e6)) |>
  dplyr::select(-TA_mol_kg, -DIC)

# ── Merge DOC and compute inflow-referenced delta variables ───────────────────
pHSlope2 <- pHSlope |>
  left_join(
    DIC_calc |> dplyr::select(any_of(names(pHSlope)), DIC_umol_kg),
    by = intersect(names(pHSlope), names(DIC_calc))
  ) |>
  mutate(TREATMENT = ifelse(is.na(TREATMENT), "Inflow", TREATMENT)) |>
  full_join(
    DOC_data |> dplyr::select(-DATETIME),
    by = intersect(names(pHSlope), names(DOC_data))
  )

InflowData <- pHSlope2 |>
  filter(TANK_NUM %in% c("Inflow1", "Inflow2")) |>
  dplyr::select(-c(FLOW_LEFT, FLOW_RIGHT, Notes, SALINITY, TEMPINSITU)) |>
  rename(
    pH_inflow  = pH,
    TA_inflow  = TA,
    DIC_inflow = DIC_umol_kg,
    DOC_inflow = NPOC_uM
  ) |>
  mutate(INFLOW_TABLE = ifelse(TANK_NUM == "Inflow1", 1, 2)) |>
  ungroup() |>
  dplyr::select(DATE, TIME, INFLOW_TABLE, pH_inflow, TA_inflow, DIC_inflow, DOC_inflow)

# Mesocosm benthic tile footprint (22.5 × 22.5 cm)
SurfaceArea <- 22.5 * 22.5

Data <- pHSlope2 |>
  ungroup() |>
  filter(!TANK_NUM %in% c("Inflow1", "Inflow2")) |>
  mutate(TANK_NUM = as.numeric(TANK_NUM)) |>
  left_join(TableID |> dplyr::select(TANK_NUM, INFLOW_TABLE), by = "TANK_NUM") |>
  left_join(InflowData, by = c("DATE", "TIME", "INFLOW_TABLE")) |>
  mutate(
    DATETIME       = ymd_hms(paste(DATE, TIME)),
    deltapH        = pH - pH_inflow,
    deltaDOC       = NPOC_uM - DOC_inflow,
    totalflow      = FLOW_RIGHT + FLOW_LEFT,
    # Tank volume 10 L = 10,000 mL; flow in mL/min; result in hours
    residence_time = (1 / totalflow) * (10000 / 60),
    flowrate       = totalflow / 60,
    # Positive = net community uptake (inflow minus outflow)
    deltaTA  = TA_inflow - TA,
    deltaDIC = DIC_inflow - DIC_umol_kg,
    # NEC via alkalinity anomaly (÷2 for 2:1 TA:CaCO₃; ×1.025 kg/L seawater density)
    NEC = (deltaTA / 2) * 1.025 * 10 * (1 / residence_time) * (1 / SurfaceArea),
    # NEP via DIC anomaly minus calcification-driven DIC drawdown
    NEP = (deltaDIC * 1.025 * 10 * (1 / residence_time) * (1 / SurfaceArea)) - NEC
  ) |>
  rename(DOC = NPOC_uM)

# ── Outlier removal ────────────────────────────────────────────────────────────
# Tukey outer fences (IQR × 3) applied across all observations within each
# time-point block. Fences computed pooled (not per treatment).
# Noon (12:00): DOC, NEC, NEP, pH, TA
# 9 PM (21:00): DOC, NEC, NEP, TA  (pH excluded at night per .qmd convention)
# Other time points: no outlier removal applied

remove_outliers <- function(x, multiplier = 3) {
  q   <- quantile(x, c(0.25, 0.75), na.rm = TRUE)
  iqr <- q[2] - q[1]
  ifelse(x < (q[1] - multiplier * iqr) | x > (q[2] + multiplier * iqr), NA, x)
}

chem_noon <- Data |>
  filter(TIME == hms::as_hms("12:00:00")) |>
  mutate(across(c(DOC, NEC, NEP, pH, TA), remove_outliers))

chem_night <- Data |>
  filter(TIME == hms::as_hms("21:00:00")) |>
  mutate(across(c(DOC, NEC, NEP, TA), remove_outliers))

chem_other <- Data |>
  filter(!TIME %in% hms::as_hms(c("12:00:00", "21:00:00")))

# ── Assemble and export ────────────────────────────────────────────────────────
carbonate_chemistry_bcodmo <- bind_rows(chem_noon, chem_night, chem_other) |>
  arrange(TANK_NUM, DATETIME) |>
  mutate(DATE = format(as.Date(as.character(DATE), "%Y%m%d"))) |>
  dplyr::select(
    # Identifiers
    DATE, TIME, DATETIME, TANK_NUM, TREATMENT,
    # Environmental conditions
    TEMPINSITU, TEMPINLAB, SALINITY,
    # Hydraulics
    FLOW_LEFT, FLOW_RIGHT, residence_time, flowrate,
    # Carbonate chemistry (measured and calculated)
    TA, pH, DIC_umol_kg, DOC,
    # Inflow reference values
    pH_inflow, TA_inflow, DIC_inflow, DOC_inflow,
    # Delta from inflow
    deltapH, deltaTA, deltaDIC, deltaDOC,
    # Community metabolic fluxes
    NEC, NEP,
    # QC notes
    Notes
  )

write_csv(carbonate_chemistry_bcodmo, here("output", "bcodmo_carbonate_chemistry.csv"))

cat("carbonate_chemistry:", nrow(carbonate_chemistry_bcodmo), "rows,",
    ncol(carbonate_chemistry_bcodmo), "cols\n")
cat("Outlier NAs introduced per variable:\n")
carbonate_chemistry_bcodmo |>
  dplyr::select(DOC, NEC, NEP, pH, TA) |>
  summarise(across(everything(), ~sum(is.na(.)))) |>
  pivot_longer(everything(), names_to = "variable", values_to = "n_NA") |>
  print()
