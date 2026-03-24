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

// =============================================================
// Load timeseries and merge
// =============================================================
import delimited ../../get_metrics/output/pkg_human_downloads_extended.csv, clear
rename date date_str
gen date = date(date_str, "YMD")
format date %td
encode pkg, gen(pkg_id)

merge m:1 pkg using `covs', keep(master match)
tab _merge
drop _merge

local snapshot_dates 2023-06-20 2023-07-20 2023-08-20 2023-09-20 2023-10-20
local fmt %9.1fc


// =============================================================
// Analyze ITT
// =============================================================
foreach het_var of local hetvars {
    eststo clear

    foreach snapshot_date of local snapshot_dates {

        eststo: qreg tt_downloads i.treatment2##i.`het_var' ///
            if date == date("`snapshot_date'", "YMD"), ///
            vce(robust) quantile(.5)

        quietly sum `e(depvar)' if e(sample), detail
        local ymed = r(p50)

        estadd scalar ymedian = `ymed'
        estadd scalar nobs = e(N)
        estadd scalar n_packages = e(N)
        estadd scalar n_days = 1
    }

    local Hlabel = cond("`het_var'"=="high_size_mb",      "Large repository size", ///
                   cond("`het_var'"=="high_raw_readme_len",      "Long raw description", ///
                   cond("`het_var'"=="high_processed_readme_len","Long readme documentation", "`het_var'")))

    dis as red "====================================================="
    dis as red "ITT: HETEROGENEITY by `het_var' as binary"
    dis as red "====================================================="  
    esttab, varwidth(30) nobase

    local savepath "../output/github_exp_medians_regtable_allhumaninstallers_`het_var'_extended.tex"
    #delimit ;
    esttab using "`savepath'",
        cell(
            b (fmt(`fmt') star)
            se(par fmt(`fmt'))
            ci(par(\multicolumn{1}{c}{\text{[$ \:\text{to}\: $]}}) fmt(`fmt'))
            p (par(\multicolumn{1}{c}{\text{$<p= >$}}) fmt(%9.3f))
        )
        collabels(, none)
        nonumber nomtitle noobs noomitted nobaselevels
        star(+ 0.1 * 0.05 ** 0.01 *** 0.001)
        coeflabels(
            _cons "Constant"
            1.treatment2 "Treatment (low dosage)"
            2.treatment2 "Treatment (high dosage)"
            1.`het_var' "`Hlabel'"
            1.treatment2#1.`het_var' "Treatment (low) $\times$ `Hlabel'"
            2.treatment2#1.`het_var' "Treatment (high) $\times$ `Hlabel'"
        )
        order(
            1.treatment2 2.treatment2
            1.`het_var'
            1.treatment2#1.`het_var' 2.treatment2#1.`het_var'
        )
        scalar(
            "ymedian Median of outcome"
            "n_packages Package observations"
            "n_days Day observations"
            "nobs Package-day observations"
        )
        fragment substitute(\_ _) booktabs replace
    ;
    #delimit cr
}

// =============================================================
// Analyze LATE
// =============================================================
foreach het_var of local hetvars {
    eststo clear
    foreach snapshot_date of local snapshot_dates {
        eststo: ivreg2 tt_downloads i.`het_var' ///
            (i.treated i.treated#i.`het_var' = i.treatment i.treatment#i.`het_var') ///
            if date==date("`snapshot_date'", "YMD"), r first
            sum `e(depvar)' if e(sample)
            local ymean: display %9.1fc `r(mean)'
            estadd local ymean "`ymean'"
            local nobs: display %9.0fc `e(N)'
            estadd local nobs "`nobs'"
            estadd local n_packages "`nobs'"
            estadd local n_days 1
    }


    dis as red "====================================================="
    dis as red "LATE: HETEROGENEITY by `het_var' as binary"
    dis as red "====================================================="    
    esttab, varwidth(30) nobase

    local savepath "../output/github_exp_het_`het_var'_late_extended.tex"
    #delimit ;
    esttab using "`savepath'",
        cell(
            b (fmt(`fmt') star)
            se(par fmt(`fmt'))
            ci(par(\multicolumn{1}{c}{\text{[$ \:\text{to}\: $]}}) fmt(`fmt'))
            p (par(\multicolumn{1}{c}{\text{$<p= >$}}) fmt(%9.3f))
        )
        collabels(, none)
        nonumber nomtitle noobs noomitted nobaselevels
        star(+ 0.1 * 0.05 ** 0.01 *** 0.001)
        coeflabels(
            _cons "Constant"
            1.treated "Received treatment"
            1.`het_var' "`Hlabel'"
            1.treated#1.`het_var' "Received treatment $\times$ `Hlabel'"
        )
        order(
            1.treated
            1.`het_var'
            1.treated#1.`het_var'
        )
        scalar(
            "ymean Mean of outcome"
            "n_packages Package observations"
            "n_days Day observations"
            "nobs Package-day observations"
        )
        fragment substitute(\_ _) booktab replace
    ;
    #delimit cr
}


// =============================================================
// Analyze ITT with continuous heterogeneity
// =============================================================
foreach het_var of local pkg_complex {
    eststo clear

    foreach snapshot_date of local snapshot_dates {

        eststo: qreg tt_downloads ///
            i.treatment2##c.`het_var' ///
            if date == date("`snapshot_date'", "YMD"), ///
            vce(robust) quantile(.5)

        quietly sum `e(depvar)' if e(sample), detail
        local ymed = r(p50)

        estadd scalar ymedian = `ymed'
        estadd scalar nobs = e(N)
        estadd scalar n_packages = e(N)
        estadd scalar n_days = 1
    }

    local Hlabel = cond("`het_var'"=="size_mb",                 "Repository size (MB)", ///
                   cond("`het_var'"=="raw_readme_len",          "Raw description length", ///
                   cond("`het_var'"=="processed_readme_len",    "Readme documentation length", "`het_var'")))

    dis as red "====================================================="
    dis as red "ITT: HETEROGENEITY by `het_var' as continuous"
    dis as red "====================================================="
    esttab, varwidth(30) nobase
    
    local savepath "../output/github_exp_continuous_regtable_allhumaninstallers_`het_var'_extended.tex"
    #delimit ;
    esttab using "`savepath'",
        cell(
            b (fmt(`fmt') star)
            se(par fmt(`fmt'))
            ci(par(\multicolumn{1}{c}{\text{[$ \:\text{to}\: $]}}) fmt(`fmt'))
            p (par(\multicolumn{1}{c}{\text{$<p= >$}}) fmt(%9.3f))
        )
        collabels(, none)
        nonumber nomtitle noobs noomitted nobaselevels
        star(+ 0.1 * 0.05 ** 0.01 *** 0.001)
        coeflabels(
            _cons "Constant"
            1.treatment2 "Treatment (low dosage)"
            2.treatment2 "Treatment (high dosage)"
            c.`het_var' "`Hlabel' (continuous)"
            1.treatment2#c.`het_var' "Treatment (low) $\times$ `Hlabel'"
            2.treatment2#c.`het_var' "Treatment (high) $\times$ `Hlabel'"
        )
        order(
            1.treatment2 2.treatment2
            c.`het_var'
            1.treatment2#c.`het_var' 2.treatment2#c.`het_var'
        )
        scalar(
            "ymedian Median of outcome"
            "n_packages Package observations"
            "n_days Day observations"
            "nobs Package-day observations"
        )
        fragment substitute(\_ _) booktabs replace
    ;
    #delimit cr    
}

// =============================================================
// Analyze LATE (continuous heterogeneity)
// =============================================================
foreach het_var of local pkg_complex {
    eststo clear

    foreach snapshot_date of local snapshot_dates {
        eststo: ivreg2 tt_downloads c.`het_var' ///
            (i.treated i.treated#c.`het_var' = i.treatment i.treatment#c.`het_var') ///
            if date == date("`snapshot_date'", "YMD"), r first

        quietly sum `e(depvar)' if e(sample)
        local ymean: display %9.1fc `r(mean)'
        estadd local ymean "`ymean'"
        local nobs: display %9.0fc `e(N)'
        estadd local nobs "`nobs'"
        estadd local n_packages "`nobs'"
        estadd local n_days 1
    }

    local Hlabel = cond("`het_var'"=="size_mb",                 "Repository size (MB)", ///
                   cond("`het_var'"=="raw_readme_len",          "Raw description length", ///
                   cond("`het_var'"=="processed_readme_len",    "Readme documentation length", "`het_var'")))

    dis as red "====================================================="
    dis as red "LATE: HETEROGENEITY by `het_var' as continuous"
    dis as red "====================================================="
    esttab, varwidth(30) nobase

    local savepath "../output/github_exp_continuous_het_`het_var'_late_extended.tex"
    #delimit ;
    esttab using "`savepath'",
        cell(
            b (fmt(`fmt') star)
            se(par fmt(`fmt'))
            ci(par(\multicolumn{1}{c}{\text{[$ \:\text{to}\: $]}}) fmt(`fmt'))
            p (par(\multicolumn{1}{c}{\text{$<p= >$}}) fmt(%9.3f))
        )
        collabels(, none)
        nonumber nomtitle noobs noomitted nobaselevels
        star(+ 0.1 * 0.05 ** 0.01 *** 0.001)
        coeflabels(
            _cons "Constant"
            1.treated "Received treatment"
            c.`het_var' "`Hlabel' (continuous)"
            1.treated#c.`het_var' "Received treatment $\times$ `Hlabel'"
        )
        order(
            1.treated
            c.`het_var'
            1.treated#c.`het_var'
        )
        scalar(
            "ymean Mean of outcome"
            "n_packages Package observations"
            "n_days Day observations"
            "nobs Package-day observations"
        )
        fragment substitute(\_ _) booktabs replace
    ;
    #delimit cr    
}
