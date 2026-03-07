set more off
import delimited ../../baltest/output/gh_experiment_timeseries_gharchive_events.csv, clear

rename date date_str
gen date = date(date_str, "YMD")

rename full_name repo_str
encode repo_str, gen(repo)

* Date when treatment happens
local cutoff_date_str 2023-05-20
gen cutoff_date= date("`cutoff_date_str'", "YMD")
gen t = date - cutoff_date

local ghevents tt_watchevent tt_pushevent tt_pullrequestevent tt_issuesopened tt_issuesclosed tt_forkevent tt_releaseevent

foreach post_snapshot_date in 2023-07-01 2023-12-31 {

local end_date = date("`post_snapshot_date'", "YMD")
local delta_days_obs = `end_date' - cutoff_date

// =============================================================
// Medians
// =============================================================
eststo clear
foreach outcome of varlist `ghevents' {
	// Post-treat differences snapshot at `post_snapshot_date'
	eststo: qreg `outcome' i.treated if date==date("`post_snapshot_date'", "YMD"), vce(r) quantile(.5)
		* Add scalars
		// Get mean of y -----------------------------------
		sum `e(depvar)' if e(sample), d
		local ymean: display %9.0fc `r(p50)'
		estadd local ymean "`ymean'"
		// Get obs -----------------------------------------
		local nobs: display %9.0fc `e(N)'
		estadd local nobs "`nobs'"
		// Get repos/N_clusters ----------------------------
		estadd local n_repos "582"
		// Get days ----------------------------------------
		estadd local n_days 1

	// Post-treat differences allowing for dynamics
	eststo: qreg2 `outcome' i.treated##c.t if date>cutoff_date, cluster(repo) quantile(.5)
		* Add scalars
		// Get mean of y -----------------------------------
		sum `e(depvar)' if e(sample), d
		local ymean: display %9.0fc `r(p50)'
		estadd local ymean "`ymean'"
		// Get obs -----------------------------------------
		local nobs: display %9.0fc `e(N)'
		estadd local nobs "`nobs'"
		// Get repos/N_clusters ----------------------------
		estadd local n_repos "582"
		// Get days ----------------------------------------
		estadd local n_days `delta_days_obs'
}

#delimit;
esttab,
	varwidth(25)
	se
	collabels(, none)
	noomitted
    nobaselevels
	star(+ 0.1 * 0.05 ** 0.01 *** 0.001)
	coeflabels(
		_cons "Constant"
		1.treated "Treatment group"
		t "Linear trend"
		1.treated#c.t "Treatment group  $ \times$ Linear trend"
	)
	order(
		1.treated
		t
		1.treated#c.t
	)
	scalar(
		// "r2 R$^2$"
		"ymean Median/Mean of outcome"
		"n_repos Repository observations"
		"n_days Day observations"
		"nobs Repository-day observations"
	)
	// Other LaTeX settings
;
#delimit cr
local savepath using ../output/gh_exp_regtable_gharchive_medians_`post_snapshot_date'.tex
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
		1.treated "Treatment group"
		t "Linear trend"
		1.treated#c.t "Treatment group  $ \times$ Linear trend"
	)
	scalar(
		// "r2 R$^2$"
		"ymean Median/Mean of outcome"
		"n_repos Repository observations"
		"n_days Day observations"
		"nobs Repository-day observations"
	)
	// Other LaTeX settings
	fragment
	substitute(\_ _)
	booktab
	replace	
;
#delimit cr

eststo clear
// =============================================================
// Means
// =============================================================
foreach outcome of varlist `ghevents' {
	// Post-treat differences snapshot at `post_snapshot_date'
	eststo: reg `outcome' i.treated if date==date("`post_snapshot_date'", "YMD"), vce(hc3)
		* Add scalars
		// Get mean of y -----------------------------------
		sum `e(depvar)' if e(sample), d
		local ymean: display %9.0fc `r(p50)'
		estadd local ymean "`ymean'"
		// Get obs -----------------------------------------
		local nobs: display %9.0fc `e(N)'
		estadd local nobs "`nobs'"
		// Get repos/N_clusters ----------------------------
		estadd local n_repos "582"
		// Get days ----------------------------------------
		estadd local n_days 1

	// Post-treat differences allowing for dynamics
	eststo: reg `outcome' i.treated##c.t if date>cutoff_date, cluster(repo)
		* Add scalars
		// Get mean of y -----------------------------------
		sum `e(depvar)' if e(sample), d
		local ymean: display %9.0fc `r(p50)'
		estadd local ymean "`ymean'"
		// Get obs -----------------------------------------
		local nobs: display %9.0fc `e(N)'
		estadd local nobs "`nobs'"
		// Get repos/N_clusters ----------------------------
		estadd local n_repos "582"
		// Get days ----------------------------------------
		estadd local n_days `delta_days_obs'
}

#delimit;
esttab,
	varwidth(25)
	se
	collabels(, none)
	noomitted
    nobaselevels
	star(+ 0.1 * 0.05 ** 0.01 *** 0.001)
	coeflabels(
		_cons "Constant"
		1.treated "Treatment group"
		t "Linear trend"
		1.treated#c.t "Treatment group  $ \times$ Linear trend"
	)
	order(
		1.treated
		t
		1.treated#c.t
	)
	scalar(
		// "r2 R$^2$"
		"ymean Median/Mean of outcome"
		"n_repos Repository observations"
		"n_days Day observations"
		"nobs Repository-day observations"
	)
	// Other LaTeX settings
;
#delimit cr
local savepath using ../output/gh_exp_regtable_gharchive_means_`post_snapshot_date'.tex
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
		1.treated "Treatment group"
		t "Linear trend"
		1.treated#c.t "Treatment group  $ \times$ Linear trend"
	)
	scalar(
		// "r2 R$^2$"
		"ymean Median/Mean of outcome"
		"n_repos Repository observations"
		"n_days Day observations"
		"nobs Repository-day observations"
	)
	// Other LaTeX settings
	fragment
	substitute(\_ _)
	booktab
	replace	
;
#delimit cr
}
