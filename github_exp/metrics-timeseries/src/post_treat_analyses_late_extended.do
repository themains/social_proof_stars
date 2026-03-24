// =============================================================
// GitHub experiment — LATE estimates (extended to Oct 31, 2023)
// Treatment ended May 20, 2023
// Instrument: treatment (ITT assignment)
// Endogenous: treated (compliance = received >=20 stars)
// Snapshots at 1-5 months post-treatment: Jun 20, Jul 20, Aug 20, Sep 20, Oct 20
// Dynamics: May 20 – Oct 31 (165 days)
// =============================================================
set more off
cls
import delimited ../../get_metrics/output/pkg_human_downloads_extended.csv, clear
rename date date_str
gen date = date(date_str, "YMD")

rename pkg pkg_str
encode pkg_str, gen(pkg)

local cutoff_date_str 2023-05-20
gen cutoff_date= date("`cutoff_date_str'", "YMD")
gen t = date - cutoff_date

local end_date = date("2023-10-31", "YMD")
local delta_days_obs = `end_date' - date("`cutoff_date_str'", "YMD") + 1


// =============================================================
// LATE (Means)
// =============================================================
eststo clear
* --------------------------------------------------------------
* Snapshot at Jun 20 (1 month relative to May 20 end of treatment period)
local _post_snapshot_date 2023-06-20
eststo: ivreg2 tt_downloads (i.treated=i.treatment) if date==date("`_post_snapshot_date'", "YMD"), r first
	* Add scalars
	sum `e(depvar)' if e(sample)
	local ymean: display %9.1fc `r(mean)'
	estadd local ymean "`ymean'"
	local nobs: display %9.0fc `e(N)'
	estadd local nobs "`nobs'"
	estadd local n_packages "`nobs'"
	estadd local n_days 1

* --------------------------------------------------------------
* Snapshot at Jul 20
local _post_snapshot_date 2023-07-20
eststo: ivreg2 tt_downloads (i.treated=i.treatment) if date==date("`_post_snapshot_date'", "YMD"), r first
	sum `e(depvar)' if e(sample)
	local ymean: display %9.1fc `r(mean)'
	estadd local ymean "`ymean'"
	local nobs: display %9.0fc `e(N)'
	estadd local nobs "`nobs'"
	estadd local n_packages "`nobs'"
	estadd local n_days 1

* --------------------------------------------------------------
* Snapshot at Aug 20
local _post_snapshot_date 2023-08-20
eststo: ivreg2 tt_downloads (i.treated=i.treatment) if date==date("`_post_snapshot_date'", "YMD"), r first
	sum `e(depvar)' if e(sample)
	local ymean: display %9.1fc `r(mean)'
	estadd local ymean "`ymean'"
	local nobs: display %9.0fc `e(N)'
	estadd local nobs "`nobs'"
	estadd local n_packages "`nobs'"
	estadd local n_days 1

* --------------------------------------------------------------
* Snapshot at Sep 20
local _post_snapshot_date 2023-09-20
eststo: ivreg2 tt_downloads (i.treated=i.treatment) if date==date("`_post_snapshot_date'", "YMD"), r first
	sum `e(depvar)' if e(sample)
	local ymean: display %9.1fc `r(mean)'
	estadd local ymean "`ymean'"
	local nobs: display %9.0fc `e(N)'
	estadd local nobs "`nobs'"
	estadd local n_packages "`nobs'"
	estadd local n_days 1

* --------------------------------------------------------------
* Snapshot at Oct 20
local _post_snapshot_date 2023-10-20
eststo: ivreg2 tt_downloads (i.treated=i.treatment) if date==date("`_post_snapshot_date'", "YMD"), r first
	sum `e(depvar)' if e(sample)
	local ymean: display %9.1fc `r(mean)'
	estadd local ymean "`ymean'"
	local nobs: display %9.0fc `e(N)'
	estadd local nobs "`nobs'"
	estadd local n_packages "`nobs'"
	estadd local n_days 1

* --------------------------------------------------------------
* Post-treat differences allowing for dynamics
eststo: ivreg2 tt_downloads t (i.treated i.treated#c.t = i.treatment i.treatment#c.t) if date>=cutoff_date, cluster(pkg) first
	sum `e(depvar)' if e(sample)
	local ymean: display %9.1fc `r(mean)'
	estadd local ymean "`ymean'"
	local nobs: display %9.0fc `e(N)'
	estadd local nobs "`nobs'"
	estadd local n_packages `e(N_clust)'
	estadd local n_days `delta_days_obs'

local savepath using ../output/github_exp_regtable_allhumaninstallers_late_extended.tex
local fmt %9.1fc
#delimit;
esttab `savepath',
	cell(
		b (    fmt(`fmt') star)
		se(par fmt(`fmt'))
		ci(par(\multicolumn{1}{c}{\text{[$ \:\text{to}\: $]}}) fmt(`fmt'))
		p (par(\multicolumn{1}{c}{\text{$<p= >$}})             fmt(%9.3f))
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
		1.treated#c.t "Received treatment $ \times$ Linear trend"
	)
	order(
		1.treated
		t
		1.treated#c.t
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
