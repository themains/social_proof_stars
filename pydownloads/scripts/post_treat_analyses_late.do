set more off
import delimited ../data/pypi_experiment_timeseries.csv, clear

rename date date_str
gen date = date(date_str, "YMD")

rename file_project pkg_str
encode pkg_str, gen(pkg)

* Date when treatment happens
local cutoff_date_str 2023-06-08
gen cutoff_date= date("`cutoff_date_str'", "YMD")
gen t = date - cutoff_date

* End date of sample period
local end_date = date("2023-07-20", "YMD")
local delta_days_obs = `end_date' - cutoff_date + 1

local post_snapshot_date 2023-06-22

assert (diff_intervention == 0) if (treatment == 0)

eststo clear
// =============================================================
// Means only
// =============================================================
// Post-treat differences snapshot at `post_snapshot_date'
// eststo: ivqreg tt_downloads (treated = treatment), vce(r) q(.5)

eststo: ivreg2 tt_downloads (i.treated = i.treatment) if date==date("`post_snapshot_date'", "YMD"), r first
    * Add scalars
    // Get mean of y -----------------------------------
    sum `e(depvar)' if e(sample)
    local ymean: display %9.0fc `r(mean)'
    estadd local ymean "`ymean'"
    // Get obs -----------------------------------------
    local nobs: display %9.0fc `e(N)'
    estadd local nobs "`nobs'"
    // Get packages/N_clusters -------------------------
    estadd local n_packages "`nobs'"
    // Get days ----------------------------------------
    estadd local n_days 1

eststo: ivreg2 tt_downloads t (i.treated i.treated#c.t = i.treatment i.treatment#c.t) if date>cutoff_date, cluster(pkg) first
    * Add scalars
    // Get mean of y -----------------------------------
    sum `e(depvar)' if e(sample)
    local ymean: display %9.0fc `r(mean)'
    estadd local ymean "`ymean'"
    // Get obs -----------------------------------------
    local nobs: display %9.0fc `e(N)'
    estadd local nobs "`nobs'"
    // Get packages/N_clusters -------------------------
    local n_pkg: display %9.0fc `e(N_clust)'
    estadd local n_packages "`n_pkg'"
    // Get days ----------------------------------------
    estadd local n_days `delta_days_obs'


#delimit;
esttab,
    varwidth(40)
    se
    collabels(, none)
    noomitted
    nobaselevels
    star(+ 0.1 * 0.05 ** 0.01 *** 0.001)
    coeflabels(
        _cons "Constant"
        1.treated "Received treatment"
        t "Linear trend"
        1.treated#c.t "Received treatment  $ \times$ Linear trend"
    )
    order(
        1.treated
        t
        1.treated#c.t
    )
    scalar(
        // "r2 R$^2$"
        "ymean Mean of outcome"
        "n_packages Package observations"
        "n_days Day observations"
        "nobs Package-day observations"
    )
    // Other LaTeX settings
;
#delimit cr

local savepath using ../tabs/pypi_exp_regtable_late.tex
local fmt %9.1fc
#delimit;
esttab `savepath',
    cell(
        b (    fmt(`fmt') star) 
        se(par fmt(`fmt'))
        ci(par(\multicolumn{1}{c}{\text{[$ \:\text{to}\: $]}}) fmt(`fmt'))
        p (par(\multicolumn{1}{c}{\text{$<p= >$}})         fmt(%4.3f)) 
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
        1.treated "Received treatment"
        t "Linear trend"
        1.treated#c.t "Received treatment  $ \times$ Linear trend"
    )
    order(
        1.treated
        t
        1.treated#c.t
    )
    scalar(
        // "r2 R$^2$"
        "ymean Mean of outcome"
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


