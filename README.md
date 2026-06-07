# paneltools

A collection of R helper functions for visualising Difference-in-Differences (DiD) estimates from panel data, built around the `DIDmultiplegtSTAT` package by de Chaisemartin et al.

---

## Functions

| Function | Description |
|---|---|
| `plot_stat` | Plot AOSS / WAOSS / IV-WAOSS estimates from one or more `did_multiplegt_stat` models |

---

## `plot_stat`

### What it does

`plot_stat` takes a **named list of `did_multiplegt_stat` models** and produces a dot-and-CI plot comparing their estimates. It automatically reads what estimators were used and whether a placebo test was run — no manual configuration needed.

Key features:
- **Auto-detects estimators** (AOSS, WAOSS, IV-WAOSS) from each model's stored arguments
- **Auto-detects placebo** — shows placebo estimates as hollow points only when `placebo = TRUE` was used; skips them silently otherwise
- **Model labels** — the x-axis shows each model's name plus a short config tag (e.g. `exact match, RA`)
- **Plot title** — shows the outcome variable, treatment variable, and unit identifier

### Dependencies

```r
install.packages(c("tidyverse", "DIDmultiplegtSTAT"))
```

Load before using:

```r
library(tidyverse)
library(DIDmultiplegtSTAT)
source("R/plot_stat.R")
```

---

### Tutorial

#### Step 1 — Load data

```r
library(arrow)
library(here)

data <- read_parquet(here("N", "2. data", "2.1. de Chaisemartin", "deryugina_2017.parquet"))
```

#### Step 2 — Run `did_multiplegt_stat` models

Run as many models as you want to compare and collect them in a named list.

```r
# Model 1: exact matching (binary/discrete treatment)
m1 <- did_multiplegt_stat(
  df          = data,
  Y           = "log_curr_trans_ind_gov_pc",
  ID          = "county_fips",
  Time        = "year",
  D           = "hurricane",
  exact_match = TRUE,
  estimator   = c("aoss", "waoss"),
  switchers   = "up",
  placebo     = TRUE
)

# Model 2: regression adjustment without exact matching
m2 <- did_multiplegt_stat(
  df          = data,
  Y           = "log_curr_trans_ind_gov_pc",
  ID          = "county_fips",
  Time        = "year",
  D           = "hurricane",
  exact_match = FALSE,
  estimator   = c("aoss", "waoss"),
  placebo     = TRUE
)

models <- list(m1 = m1, m2 = m2)
```

You can inspect any model with `summary()`:

```r
summary(m1)
```

#### Step 3 — Plot

```r
source("R/plot_stat.R")

plot_stat(models)
```

This produces a plot with:
- one point per estimator (AOSS / WAOSS) per model
- 95% confidence intervals
- filled points = main estimates, hollow points = placebo

#### Options

**Show only one estimator:**

```r
plot_stat(models, estimator = "waoss")
```

**Suppress placebo even when it was run:**

```r
plot_stat(models, show_placebo = FALSE)
```

**Single model:**

```r
plot_stat(list(baseline = m1))
```

---

### Output structure of `did_multiplegt_stat`

For reference, the main slots of a `did_multiplegt_stat` object are:

| Slot | Contents |
|---|---|
| `$args` | All arguments passed to the function (`Y`, `D`, `ID`, `estimator`, `exact_match`, …) |
| `$results$table` | Matrix with rows `AOSS`, `WAOSS`, `IVWAOSS` (aggregated) and period-level rows `aoss_2`, `waoss_2`, … Columns: `Estimate`, `SE`, `LB CI`, `UB CI`, `Switchers`, `Stayers` |
| `$results$table_placebo` | Same structure as `$results$table`; only present when `placebo = TRUE` |
| `$results$pairs` | Number of time periods |
| `$results$aoss_vs_waoss` | Test of AOSS = WAOSS; only present when `aoss_vs_waoss = TRUE` |

---

## References

de Chaisemartin, C., D'Haultfoeuille, X., Pasquier, F., Vazquez-Bare, G. (2022). *Difference-in-Differences for Continuous Treatments and Instruments with Stayers*. [SSRN 4011782](https://ssrn.com/abstract=4011782)

de Chaisemartin, C., D'Haultfoeuille, X. (2020). *Two-Way Fixed Effects Estimators with Heterogeneous Treatment Effects*. *American Economic Review*, 110(9), 2964–2996.
