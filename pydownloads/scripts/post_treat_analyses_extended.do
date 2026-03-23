set more off
import delimited ../data/pypi_experiment_timeseries.csv, clear

rename date date_str
gen date = date(date_str, "YMD")

rename file_project pkg_str
encode pkg_str, gen(pkg)

* Date when treatment ends
local cutoff_date_str 2023-06-08
gen cutoff_date= date("`cutoff_date_str'", "YMD")
gen t = date - cutoff_date

local end_date = date("2023-10-31", "YMD")
local delta_days_obs = `end_date' - date("`cutoff_date_str'", "YMD") + 1


// =============================================================
// Means
// =============================================================
eststo clear
* --------------------------------------------------------------
* Snapshot at 8 Jul (1 month post 8 Jun end of treatment)
local _post_snapshot_date 2023-07-08
eststo: reg tt_downloads i.treatment if date==date("`_post_snapshot_date'", "YMD"), vce(hc3)
	* Add scalars
	sum `e(depvar)' if e(sample)
	local ymean: display %9.1fc `r(mean)'
	estadd local ymean "`ymean'"
	local nobs: display %9.0fc `e(N)'
	estadd local nobs "`nobs'"
	estadd local n_packages "`nobs'"
	estadd local n_days 1

* --------------------------------------------------------------
* Snapshot at 8 Aug (2 months)
local _post_snapshot_date 2023-08-08
eststo: reg tt_downloads i.treatment if date==date("`_post_snapshot_date'", "YMD"), vce(hc3)
	sum `e(depvar)' if e(sample)
	local ymean: display %9.1fc `r(mean)'
	estadd local ymean "`ymean'"
	local nobs: display %9.0fc `e(N)'
	estadd local nobs "`nobs'"
	estadd local n_packages "`nobs'"
	estadd local n_days 1

* --------------------------------------------------------------
* Snapshot at 8 Sep (3 months)
local _post_snapshot_date 2023-09-08
eststo: reg tt_downloads i.treatment if date==date("`_post_snapshot_date'", "YMD"), vce(hc3)
	sum `e(depvar)' if e(sample)
	local ymean: display %9.1fc `r(mean)'
	estadd local ymean "`ymean'"
	local nobs: display %9.0fc `e(N)'
	estadd local nobs "`nobs'"
	estadd local n_packages "`nobs'"
	estadd local n_days 1

* --------------------------------------------------------------
* Snapshot at 8 Oct (4 months)
local _post_snapshot_date 2023-10-08
eststo: reg tt_downloads i.treatment if date==date("`_post_snapshot_date'", "YMD"), vce(hc3)
	sum `e(depvar)' if e(sample)
	local ymean: display %9.1fc `r(mean)'
	estadd local ymean "`ymean'"
	local nobs: display %9.0fc `e(N)'
	estadd local nobs "`nobs'"
	estadd local n_packages "`nobs'"
	estadd local n_days 1

* --------------------------------------------------------------
* Post-treat differences allowing for dynamics
eststo: reg tt_downloads i.treatment##c.t if date>=cutoff_date, cluster(pkg)
	sum `e(depvar)' if e(sample)
	local ymean: display %9.1fc `r(mean)'
	estadd local ymean "`ymean'"
	local nobs: display %9.0fc `e(N)'
	estadd local nobs "`nobs'"
	estadd local n_packages `e(N_clust)'
	estadd local n_days `delta_days_obs'

local savepath using ../tabs/pypi_exp_regtable_means.tex
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
		1.treatment "Treatment group"
		t "Linear trend"
		1.treatment#c.t "Treatment group $ \times$ Linear trend"
	)
	order(
		1.treatment
		t
		1.treatment#c.t
	)
	scalar(
		"ymean Mean of outcome"
		"n_packages Package observations"
		"n_days Day observations"
		"nobs Package-day observations"
	)
	fragment
	substitute(\_ _)
	booktab
	replace
;
#delimit cr


// =============================================================
// Medians
// =============================================================
eststo clear
* --------------------------------------------------------------
* Snapshot at 8 Jul (1 month post 8 Jun end of treatment)
local _post_snapshot_date 2023-07-08
eststo: qreg tt_downloads i.treatment if date==date("`_post_snapshot_date'", "YMD"), vce(r) quantile(.5)
	sum `e(depvar)' if e(sample), d
	local ymedian: display %9.1fc `r(p50)'
	estadd local ymedian "`ymedian'"
	local nobs: display %9.0fc `e(N)'
	estadd local nobs "`nobs'"
	estadd local n_packages "`nobs'"
	estadd local n_days 1

* --------------------------------------------------------------
* Snapshot at 8 Aug (2 months)
local _post_snapshot_date 2023-08-08
eststo: qreg tt_downloads i.treatment if date==date("`_post_snapshot_date'", "YMD"), vce(r) quantile(.5)
	sum `e(depvar)' if e(sample), d
	local ymedian: display %9.1fc `r(p50)'
	estadd local ymedian "`ymedian'"
	local nobs: display %9.0fc `e(N)'
	estadd local nobs "`nobs'"
	estadd local n_packages "`nobs'"
	estadd local n_days 1

* --------------------------------------------------------------
* Snapshot at 8 Sep (3 months)
local _post_snapshot_date 2023-09-08
eststo: qreg tt_downloads i.treatment if date==date("`_post_snapshot_date'", "YMD"), vce(r) quantile(.5)
	sum `e(depvar)' if e(sample), d
	local ymedian: display %9.1fc `r(p50)'
	estadd local ymedian "`ymedian'"
	local nobs: display %9.0fc `e(N)'
	estadd local nobs "`nobs'"
	estadd local n_packages "`nobs'"
	estadd local n_days 1

* --------------------------------------------------------------
* Snapshot at 8 Oct (4 months)
local _post_snapshot_date 2023-10-08
eststo: qreg tt_downloads i.treatment if date==date("`_post_snapshot_date'", "YMD"), vce(r) quantile(.5)
	sum `e(depvar)' if e(sample), d
	local ymedian: display %9.1fc `r(p50)'
	estadd local ymedian "`ymedian'"
	local nobs: display %9.0fc `e(N)'
	estadd local nobs "`nobs'"
	estadd local n_packages "`nobs'"
	estadd local n_days 1

* --------------------------------------------------------------
* Post-treat differences allowing for dynamics
eststo: qreg2 tt_downloads i.treatment##c.t if date>=cutoff_date, cluster(pkg) quantile(.5)
	sum `e(depvar)' if e(sample), d
	local ymedian: display %9.1fc `r(p50)'
	estadd local ymedian "`ymedian'"
	local nobs: display %9.0fc `e(N)'
	estadd local nobs "`nobs'"
	estadd local n_packages "23,965"
	estadd local n_days `delta_days_obs'

local savepath using ../tabs/pypi_exp_regtable_medians.tex
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
		1.treatment "Treatment group"
		t "Linear trend"
		1.treatment#c.t "Treatment group $ \times$ Linear trend"
	)
	order(
		1.treatment
		t
		1.treatment#c.t
	)
	scalar(
		"ymedian Median of outcome"
		"n_packages Package observations"
		"n_days Day observations"
		"nobs Package-day observations"
	)
	fragment
	substitute(\_ _)
	booktab
	replace
;
#delimit cr
