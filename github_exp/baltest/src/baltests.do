
* -----------------------------------------------------------------------------
* Program Setup
* -----------------------------------------------------------------------------
cls 					// Clear results window
clear all               // Start with a clean slate
set more off            // Disable partitioned output
macro drop _all         // Clear all macros to avoid namespace conflicts
set linesize 120        // Line size limit to make output more readable, affects logs

cap log close
log using ../output/stata-log.txt, replace text

version 13              // Still on version 13 :(

// -----------------------------------------------------------------------------
* Repo baselines
// -----------------------------------------------------------------------------
use "../../get_baseline_profile/output/repo_baselines.dta", clear

gen python_lang = (language == "Python")

local vars_to_encode "language"
foreach var of local vars_to_encode {
    rename `var' `var'_str
    encode `var'_str, gen(`var')
}

global repo_baselines size_mb fork year_created subscribers_count has_issues forks open_issues n_topics python_lang


#delimit;
iebaltab 
	$repo_baselines
	,
	total
	groupvar(treated)
	// ftest
	star(.05 .01 .001)
	stats(pair(nrmd))
	nonote
	grplabels(
		0 Control @
		1 Treated @
		)
	order(0 1)
	control(0)
	grouplabels(0 "Control packages" @ 1 "Treated packages")
	rowlabels(
		size_mb "Repository size" @
		year_created "Year created" @
		fork "Forked = 1" @
		// stargazers_count "Stars" @
		subscribers_count "Subscribers" @
		has_issues "Has issues = 1" @
		forks "Number of forks" @
		open_issues "Number of open issues" @
		n_topics "Number of topics listed" @
		python_lang	"Python = 1"
		)
	totallabel(Full sample)
	format(%9.2f)
	savetex(../output/baltest-repo-treated-01.tex) 
	replace
;

#delimit;
iebaltab 
	$repo_baselines
	,
	groupvar(treated2)
	// ftest
	star(.05 .01 .001)
	stats(pair(nrmd))
	nonote
	grplabels(
		0 Control @
		1 Treated (low) @
		2 Treated (high) @
		)	
	order(0 1 2)
	control(0)
	grouplabels(0 "Control packages" @ 1 "Treated (low dose)" @ 2 "Treated (high dose)")
	rowlabels(
		year_created "Year created" @
		fork "Forked = 1" @
		size_mb "Repository size" @
		// stargazers_count "Stars" @
		has_issues "Has issues = 1" @
		forks "Number of forks" @
		open_issues "Number of open issues" @
		subscribers_count "Subscribers" @
		n_topics "Number of topics listed" @
		python_lang	"Python = 1"
		)
	format(%9.2f)
	savetex(../output/baltest-repo-treated-012.tex) 
	replace
;
#delimit cr

// -----------------------------------------------------------------------------
* User baselines
// -----------------------------------------------------------------------------
use "../../get_baseline_profile/output/user_baselines.dta", clear

replace treated2 = 0 if (missing(treated2)) & (treated==0)

gen org = (type=="Organization")
global user_baselines public_repos public_gists followers following year_created year_updated org list_co list_email list_blog list_bio bio_size
#delimit;
iebaltab 
	$user_baselines
	,
	total
	groupvar(treated)
	// ftest
	star(.05 .01 .001)
	stats(pair(nrmd))
	nonote
	grplabels(
		0 Control @
		1 Treated @
		)	
	order(0 1)
	control(0)
	grouplabels(0 "Control packages" @ 1 "Treated packages")
	rowlabels(
		public_repos "Number of repositories" @ 
		public_gists "Number of gists" @
		followers "Number of followers" @
		following "Number of people followed" @
		year_created "Year created" @
		year_updated "Year updated" @
		org "Organization = 1" @
		list_co "List company = 1" @
		list_email "List email = 1" @
		list_blog "List personal site = 1" @
		list_bio "List brief bio = 1" @
		bio_size "Brief bio length" @
		)
	totallabel(Full sample)
	format(%9.2f)
	savetex(../output/baltest-user-treated-01.tex) 
	replace
;

#delimit;
iebaltab 
	$user_baselines
	,
	groupvar(treated2)
	// ftest
	star(.05 .01 .001)
	stats(pair(nrmd))
	nonote
	grplabels(
		0 Control @
		1 Treated (low) @
		2 Treated (high) @
		)	
	order(0 1 2)
	control(0)
	rowlabels(
		public_repos "Number of repositories" @ 
		public_gists "Number of gists" @
		followers "Number of followers" @
		following "Number of people followed" @
		year_created "Year created" @
		year_updated "Year updated" @
		org "Organization" @
		list_co "List company" @
		list_email "List email" @
		list_blog "List personal site" @
		list_bio "List brief bio" @
		bio_size "Brief bio length" @
		)
	format(%9.2f)
	savetex(../output/baltest-user-treated-012.tex) 
	replace
;
#delimit cr

// -----------------------------------------------------------------------------
* User baselines
// -----------------------------------------------------------------------------
use "../../get_baseline_profile/output/pkg_readme_requirements_baselines.dta", clear


#delimit;
iebaltab 
	raw_readme_len processed_readme_len n_requirements
	,
	total
	groupvar(treated)
	star(.05 .01 .001)
	stats(pair(nrmd))
	nonote
	grplabels(
		0 Control @
		1 Treated @
		)	
	order(0 1)
	control(0)
	grouplabels(0 "Control packages" @ 1 "Treated packages")
	rowlabels(
		raw_readme_len "Package description length" @ 
		processed_readme_len "Package description length (cleaned)" @
		n_requirements "Number of dependencies" @
		)
	totallabel(Full sample)
	format(%9.2f)
	savetex(../output/baltest-readme-treated-01.tex) 
	replace
;

#delimit;
iebaltab 
	raw_readme_len processed_readme_len n_requirements
	,
	groupvar(treated2)
	star(.05 .01 .001)
	stats(pair(nrmd))
	nonote
	grplabels(
		0 Control @
		1 Treated (low) @
		2 Treated (high) @
		)	
	order(0 1 2)
	control(0)
	rowlabels(
		raw_readme_len "Package description length" @ 
		processed_readme_len "Package description length (cleaned)" @
		n_requirements "Number of dependencies" @
		)
	format(%9.2f)
	savetex(../output/baltest-readme-treated-012.tex) 
	replace
;
#delimit cr


log close
