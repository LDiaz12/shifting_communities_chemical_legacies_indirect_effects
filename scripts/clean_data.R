library(tidyverse)
library(here)

# ── coral_physiology.csv ───────────────────────────────────────────────────────
# Drop: identifier redundant with TANK_NUM+GENOTYPE (CORAL_TANK_NUM),
#       pre-experiment baselines (initial_*),
#       pre-computed per-coral tank chemistry summaries (all _rangemean/_rangese/_mean/_se blocks),
#       and duplicate-unit physiology columns (GP_mg, R_mg)
drop_physiology <- c(
  "CORAL_TANK_NUM",
  "initial_endo", "initial_chla", "initial_biomass",
  "TA_rangemean", "TA_rangese", "TA_mean", "TA_se",
  "deltaTA_rangemean", "deltaTA_rangese", "deltaTA_mean", "deltaTA_se",
  "pH_rangemean", "pH_rangese", "pH_se",
  "deltapH_rangemean", "deltapH_rangese", "deltapH_mean", "deltapH_se",
  "DOC_rangemean", "DOC_rangese", "DOC_se",
  "deltaDOC_rangemean", "deltaDOC_rangese", "deltaDOC_mean", "deltaDOC_se",
  "NEC_rangemean", "NEC_rangese", "NEC_mean", "NEC_se",
  "NEP_rangemean", "NEP_rangese", "NEP_mean", "NEP_se",
  "GP_mg", "R_mg"
)

read_csv(here("data", "coral_physiology.csv"), show_col_types = FALSE) |>
  select(-all_of(drop_physiology)) |>
  write_csv(here("data", "coral_physiology.csv"))

# ── carbonate_chemistry.csv ───────────────────────────────────────────────────
# Drop: dissolved oxygen (DO_MG_L) and light (LIGHT_NM) — neither used in analysis
read_csv(here("data", "carbonate_chemistry.csv"), show_col_types = FALSE) |>
  select(-DO_MG_L, -LIGHT_NM) |>
  write_csv(here("data", "carbonate_chemistry.csv"))

# ── carb_chem_diel_24hr.csv ───────────────────────────────────────────────────
# Same drops as carbonate_chemistry
read_csv(here("data", "carb_chem_diel_24hr.csv"), show_col_types = FALSE) |>
  select(-DO_MG_L, -LIGHT_NM) |>
  write_csv(here("data", "carb_chem_diel_24hr.csv"))

# ── doc_tn_data.csv ───────────────────────────────────────────────────────────
# Drop: mg/L DOC duplicate (NPOC_mg_L), TN in mg/L (TN_mg_L) and µM (TN_uM)
# Only NPOC_uM (dissolved organic carbon in µmol/L) is used in analysis
read_csv(here("data", "doc_tn_data.csv"), show_col_types = FALSE) |>
  select(-NPOC_mg_L, -TN_mg_L, -TN_uM) |>
  write_csv(here("data", "doc_tn_data.csv"))
