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
use "../output/repo_gharchive_events.dta", clear

global gharchive_pre ///
    watchevent_pre ///
    pushevent_pre ///
    pullrequestevent_pre ///
    issues_opened_pre ///
    issues_closed_pre ///
    forkevent_pre ///
    releaseevent_pre 

// drop if full_name == "deepmind/mujoco"

#delimit;
iebaltab 
    $gharchive_pre
    ,
    total
    groupvar(treated)
    star(.1 .05 .01)
    stats(pair(nrmd))
    nonote
    grplabels(
        0 Control @
        1 Treated @
        )
    order(0 1)
    control(0)
    grouplabels(0 "Control repositories" @ 1 "Treated repositories")
    rowlabels(
        forkevent_pre "Fork events" @
        pullrequestevent_pre "Pull request events" @
        pushevent_pre "Push events" @
        releaseevent_pre "Release events" @
        watchevent_pre "Stars" @
        issues_opened_pre "Issues opened" @
        issues_closed_pre "Issues closed"
        )
    totallabel(Full sample)
    format(%9.2f)
    savetex(../output/baltest-gharchive-pre-treated-01.tex)
    replace
;
#delimit cr

#delimit;
iebaltab 
    $gharchive_pre
    ,
    groupvar(treated2)
    star(.1 .05 .01)
    stats(pair(nrmd))
    nonote
    grplabels(
        0 Control @
        1 Treated (low) @
        2 Treated (high) @
        )
    order(0 1 2)
    control(0)
    grouplabels(
        0 "Control repositories" @
        1 "Treated (low dose)" @
        2 "Treated (high dose)"
        )
    rowlabels(
        forkevent_pre "Fork events" @
        pullrequestevent_pre "Pull request events" @
        pushevent_pre "Push events" @
        releaseevent_pre "Release events" @
        watchevent_pre "Stars" @
        issues_opened_pre "Issues opened" @
        issues_closed_pre "Issues closed"
        )
    format(%9.2f)
    savetex(../output/baltest-gharchive-pre-treated-012.tex) 
    replace
;
#delimit cr
