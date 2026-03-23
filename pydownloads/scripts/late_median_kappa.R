library(here)
library(readr)
library(dplyr)
library(quantreg)

pypi <- read_csv(here("pydownloads/data/pypi_experiment_timeseries.csv"),
                 show_col_types = FALSE)

dat <- pypi %>%
  filter(date == "2023-06-22")

D <- as.numeric(dat$diff_intervention >= 50)
Z <- dat$treatment
Y <- dat$tt_downloads - dat$diff_intervention
p <- mean(Z)

kappa <- 1 - D * (1 - Z) / (1 - p) - (1 - D) * Z / p

keep <- kappa > 0
dat_c <- dat[keep, ]
dat_c$D <- D[keep]
dat_c$Y <- Y[keep]
w <- kappa[keep]

cat("Summary statistics:\n")
cat("N total:", nrow(dat), "\n")
cat("N kept (positive kappa):", sum(keep), "\n")
cat("N dropped (defiers):", sum(!keep), "\n")
cat("P(Z=1):", round(p, 4), "\n")
cat("Compliance rate (D=1|Z=1):", round(mean(D[Z == 1]), 4), "\n")
cat("Compliance rate (D=1|Z=0):", round(mean(D[Z == 0]), 4), "\n\n")

fit <- rq(Y ~ D, tau = 0.5, weights = w, data = dat_c)
cat("LATE at median (Abadie 2003 kappa weights):\n")
fit_summary <- summary(fit, se = "boot", R = 1000)
print(fit_summary)

cat("\n\n=== Sensitivity Analysis: diff_intervention >= 100 ===\n\n")

D_strict <- as.numeric(dat$diff_intervention >= 100)
kappa_strict <- 1 - D_strict * (1 - Z) / (1 - p) - (1 - D_strict) * Z / p

keep_strict <- kappa_strict > 0
dat_strict <- dat[keep_strict, ]
dat_strict$D <- D_strict[keep_strict]
dat_strict$Y <- Y[keep_strict]
w_strict <- kappa_strict[keep_strict]

cat("Sensitivity analysis summary:\n")
cat("N kept (positive kappa):", sum(keep_strict), "\n")
cat("N dropped (defiers):", sum(!keep_strict), "\n")
cat("Compliance rate (D=1|Z=1):", round(mean(D_strict[Z == 1]), 4), "\n")
cat("Compliance rate (D=1|Z=0):", round(mean(D_strict[Z == 0]), 4), "\n\n")

fit_strict <- rq(Y ~ D, tau = 0.5, weights = w_strict, data = dat_strict)
cat("LATE at median (stricter threshold >= 100):\n")
fit_strict_summary <- summary(fit_strict, se = "boot", R = 1000)
print(fit_strict_summary)

cat("\n\n=== Diff-in-Diff Style: Post minus Pre ===\n\n")

pre_date <- "2023-05-27"
post_date <- "2023-06-22"

dat_pre <- pypi %>% filter(date == pre_date)
dat_post <- pypi %>% filter(date == post_date)

merged <- inner_join(
  dat_pre %>% select(file_project, tt_downloads_pre = tt_downloads),
  dat_post %>% select(file_project, tt_downloads_post = tt_downloads,
                      treatment, diff_intervention),
  by = "file_project"
)

D_did <- as.numeric(merged$diff_intervention >= 50)
Z_did <- merged$treatment
Y_did <- (merged$tt_downloads_post - merged$diff_intervention) - merged$tt_downloads_pre
p_did <- mean(Z_did)

kappa_did <- 1 - D_did * (1 - Z_did) / (1 - p_did) - (1 - D_did) * Z_did / p_did

keep_did <- kappa_did > 0
dat_did <- merged[keep_did, ]
dat_did$D <- D_did[keep_did]
dat_did$Y <- Y_did[keep_did]
w_did <- kappa_did[keep_did]

cat("DiD summary:\n")
cat("N total:", nrow(merged), "\n")
cat("N kept (positive kappa):", sum(keep_did), "\n")
cat("Pre-treatment date:", pre_date, "\n")
cat("Post-treatment date:", post_date, "\n\n")

fit_did <- rq(Y ~ D, tau = 0.5, weights = w_did, data = dat_did)
cat("LATE at median (DiD style):\n")
fit_did_summary <- summary(fit_did, se = "boot", R = 1000)
print(fit_did_summary)
