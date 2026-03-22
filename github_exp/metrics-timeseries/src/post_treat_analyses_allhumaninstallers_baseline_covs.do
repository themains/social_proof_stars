cls
clear all
set more off

// =============================================================
// Load covariates and compute median splits at package level
// =============================================================
import delimited "../../get_baseline_profile/output/pypi_readme.csv", varnames(1) bindquote(strict) clear
local pkg_complex raw_readme_len processed_readme_len
keep pkg `pkg_complex'
destring `pkg_complex', replace force
duplicates drop pkg, force


* Merge in repo size
preserve
    import delimited "../output/pkg_repo_size_complexity.csv", varnames(1) clear
    tempfile size_cov
    save `size_cov'
restore
merge 1:1 pkg using `size_cov', keep(master match using) nogen

local pkg_complex `pkg_complex' size_mb

local hetvars
foreach v of local pkg_complex {
    summarize `v', detail
    local med = r(p50)
    gen high_`v' = (`v' > `med') if !missing(`v')
	local hetvars `hetvars' high_`v'
}

tempfile covs
save `covs'

local baselines forkevent_pre pullrequestevent_pre pushevent_pre releaseevent_pre watchevent_pre issues_opened_pre issues_closed_pre

// =============================================================
// Load timeseries and merge
// =============================================================
import delimited ../input/pkg_human_downloads.csv, clear
rename date date_str
gen date = date(date_str, "YMD")
format date %td
encode pkg, gen(pkg_id)

merge m:1 pkg using `covs', keep(master match)
tab _merge
drop _merge

local snapshot_dates 2023-06-21 2023-07-21 2023-08-21 2023-09-21 2023-10-21
local fmt %9.1fc

local cutoff_date_str 2023-05-20
gen cutoff_date= date("`cutoff_date_str'", "YMD")
gen t = date - cutoff_date

local end_date = date("2023-10-31", "YMD")
local delta_days_obs = `end_date' - date("`cutoff_date_str'", "YMD") + 1

// =============================================================
// Medians
// =============================================================
eststo clear
* --------------------------------------------------------------
* Snapshot at 20 Jun (1 month relative to 20 May end of treatment period)
local _post_snapshot_date 2023-06-20
eststo: qreg tt_downloads i.treatment2 `baselines' if date==date("`_post_snapshot_date'", "YMD"), vce(r) quantile(.5)
    * Add scalars
    // Get median of y -----------------------------------
    sum `e(depvar)' if e(sample), d
    local ymedian: display %9.1fc `r(p50)'
    estadd local ymedian "`ymedian'"
    // Get obs -----------------------------------------
    local nobs: display %9.0fc `e(N)'
    estadd local nobs "`nobs'"
    // Get packages/N_clusters -------------------------
    estadd local n_packages "`nobs'"
    // Get days ----------------------------------------
    estadd local n_days 1

* --------------------------------------------------------------
* Snapshot at 20 July (2 months relative to 20 May end of treatment period)
local _post_snapshot_date 2023-07-20
eststo: qreg tt_downloads i.treatment2 `baselines' if date==date("`_post_snapshot_date'", "YMD"), vce(r) quantile(.5)
    * Add scalars
    // Get median of y -----------------------------------
    sum `e(depvar)' if e(sample), d
    local ymedian: display %9.1fc `r(p50)'
    estadd local ymedian "`ymedian'"
    // Get obs -----------------------------------------
    local nobs: display %9.0fc `e(N)'
    estadd local nobs "`nobs'"
    // Get packages/N_clusters -------------------------
    estadd local n_packages "`nobs'"
    // Get days ----------------------------------------
    estadd local n_days 1


* --------------------------------------------------------------
* Snapshot at 20 August (3 months relative to 20 May end of treatment period)
local _post_snapshot_date 2023-08-20
eststo: qreg tt_downloads i.treatment2 `baselines' if date==date("`_post_snapshot_date'", "YMD"), vce(r) quantile(.5)
    * Add scalars
    // Get median of y -----------------------------------
    sum `e(depvar)' if e(sample), d
    local ymedian: display %9.1fc `r(p50)'
    estadd local ymedian "`ymedian'"
    // Get obs -----------------------------------------
    local nobs: display %9.0fc `e(N)'
    estadd local nobs "`nobs'"
    // Get packages/N_clusters -------------------------
    estadd local n_packages "`nobs'"
    // Get days ----------------------------------------
    estadd local n_days 1

* --------------------------------------------------------------
* Snapshot at 20 September (4 months relative to 20 May end of treatment period)
local _post_snapshot_date 2023-09-20
eststo: qreg tt_downloads i.treatment2 `baselines' if date==date("`_post_snapshot_date'", "YMD"), vce(r) quantile(.5)
    * Add scalars
    // Get median of y -----------------------------------
    sum `e(depvar)' if e(sample), d
    local ymedian: display %9.1fc `r(p50)'
    estadd local ymedian "`ymedian'"
    // Get obs -----------------------------------------
    local nobs: display %9.0fc `e(N)'
    estadd local nobs "`nobs'"
    // Get packages/N_clusters -------------------------
    estadd local n_packages "`nobs'"
    // Get days ----------------------------------------
    estadd local n_days 1

* --------------------------------------------------------------
* Snapshot at 20 October (5 months relative to 20 May end of treatment period)
local _post_snapshot_date 2023-10-20
eststo: qreg tt_downloads i.treatment2 `baselines' if date==date("`_post_snapshot_date'", "YMD"), vce(r) quantile(.5)
    * Add scalars
    // Get median of y -----------------------------------
    sum `e(depvar)' if e(sample), d
    local ymedian: display %9.1fc `r(p50)'
    estadd local ymedian "`ymedian'"
    // Get obs -----------------------------------------
    local nobs: display %9.0fc `e(N)'
    estadd local nobs "`nobs'"
    // Get packages/N_clusters -------------------------
    estadd local n_packages "`nobs'"
    // Get days ----------------------------------------
    estadd local n_days 1


* --------------------------------------------------------------
* Post-treat differences allowing for dynamics
eststo: qreg2 tt_downloads i.treatment2##c.t `baselines' if date>=cutoff_date, cluster(pkg) quantile(.5)
    * Add scalars
    // Get median of y -----------------------------------
    sum `e(depvar)' if e(sample), d
    local ymedian: display %9.1fc `r(p50)'
    estadd local ymedian "`ymedian'"
    // Get obs -----------------------------------------
    local nobs: display %9.0fc `e(N)'
    estadd local nobs "`nobs'"
    // Get packages/N_clusters -------------------------
    qui tabulate pkg if e(sample)
    estadd local n_packages `r(r)'
    // Get days ----------------------------------------
    estadd local n_days `delta_days_obs'


#delimit;
esttab,
    se
    collabels(, none)
    nonumber
    nomtitle
    noobs
    noomitted
    nobaselevels
    star(+ 0.1 * 0.05 ** 0.01 *** 0.001)
    coeflabels(
        _cons "Constant"
        1.treatment2 "Treatment (low dosage)"
        2.treatment2 "Treatment (high dosage)"
        t "Linear trend"
        1.treatment2#c.t "Treatment (low dosage)  $ \times$ Linear trend"
        2.treatment2#c.t "Treatment (high dosage) $ \times$ Linear trend"
    )
    order(
        1.treatment2
        2.treatment2
        t
        1.treatment2#c.t
        2.treatment2#c.t
    )
    scalar(
        "r2 R$^2$"
        "ymean Mean of outcome"
        "n_packages Package observations"
        "n_days Day observations"
        "nobs Package-day observations"
    )
;
#delimit cr

local savepath using ../output/github_exp_medians_regtable_allhumaninstallers_baseline_covs.tex
local fmt %9.1fc
#delimit;
esttab `savepath',
    cell(
        b (    fmt(`fmt') star) 
        se(par fmt(`fmt'))
        ci(par(\multicolumn{1}{c}{\text{[$ \:\text{to}\: $]}}) fmt(`fmt'))
        p (par(\multicolumn{1}{c}{\text{$<p= >$}})         fmt(%9.3f)) 
    )
    collabels(, none)
    nonumber
    nomtitle
    noobs
    noomitted
    nobaselevels
    star(+ 0.1 * 0.05 ** 0.01 *** 0.001)
    coeflabels(
        _cons "Constant"
        1.treatment2 "Treatment (low dosage)"
        2.treatment2 "Treatment (high dosage)"
        t "Linear trend"
        1.treatment2#c.t "Treatment (low dosage)  $ \times$ Linear trend"
        2.treatment2#c.t "Treatment (high dosage) $ \times$ Linear trend"
    )
    order(
        1.treatment2
        2.treatment2
        t
        1.treatment2#c.t
        2.treatment2#c.t
    )
    scalar(
        "ymedian Median of outcome"
        "n_packages Package observations"
        "n_days Day observations"
        "nobs Package-day observations"
    )
    // Other LaTeX settings
    fragment
    substitute(\_ _)
    booktab
    replace 
;
#delimit cr
