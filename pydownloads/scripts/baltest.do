* -----------------------------------------------------------------------------
* Program Setup
* -----------------------------------------------------------------------------
cls 					// Clear results window
clear all               // Start with a clean slate
set more off            // Disable partitioned output
macro drop _all         // Clear all macros to avoid namespace conflicts
set linesize 120        // Line size limit to make output more readable, affects logs

import delimited "../data/pypi_gharchive_events.csv", clear

global gharchive_pre ///
    watchevent_pre ///
    pushevent_pre ///
    pullrequestevent_pre ///
    issues_opened_pre ///
    issues_closed_pre ///
    forkevent_pre ///
    releaseevent_pre 


#delimit;
iebaltab 
    $gharchive_pre
    ,
    browse
    total
    groupvar(treatment)
    star(.05 .01 .001)
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
    savetex(../tabs/baltest-gharchive-pre-treated.tex)
    replace
;
#delimit cr    

br
