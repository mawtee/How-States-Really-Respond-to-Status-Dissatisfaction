* Open log *
************

capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\02-Controls & Components\a-Similarity\Total Bilateral Trade\scss-0102a-simtbitr-e-simm", replace

* Programme: scss-0102a-simtbitr-e-simm.do
* Project: Status Conflict among Small States
* Author: Matthew Tibbles
* Reference note: This programme is a modified transposition of the programme "msim-data11-simmeasures.do" - authored by Frank Haege and accessed at 

*******************************************************
* Calculate similarity measures for total bilateral trade
*******************************************************

* Description
*************
* This do-file calculates similarity scores for total bilateral trade using Signorino and Ritter's S, Cohen's Kappa, and Scott's Pi. 
* The inputs for these calculations are the similarity component variables for total bilateral trade


* Set up Stata *
****************
version 16
clear all
macro drop _all


/// Load appended similarity components dataset 
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\UN Voting Record\d-Similarity Components Appended\scss-0102a-simunv-d-compapp.dta", clear

/// Drop dyads that did not vote on at least one same issue during a year
drop if nobs == 0

* Generate Signorino & Ritter's S based on squared distance metric
*****************************************************************

/// Generate s denomintaor
generate denomsunv = ((3-1)^2*nobs)/2

/// Label variable
label var denomsunv "Unweighted S denominator (squared distances, UN voting record)"

// Generate unweighted s scores
generate sunv = 1-(ssd/denomsunv)

/// Label variable
label var sunv "Unweighted S (squared distances, UN voting record)"


* Generate Cohen's Kappa based on squared distance metric
********************************************************

/// Generate k denomintor
generate denomkunv = ss1+ss2 - (2/nobs)*s1*s2

/// Label variable
label var denomkunv "UN voting record k-denominator"

/// Generate chanced-corrected kappa scores
generate kunv = 1-(ssd/denomkunv) if denomkunv != 0
replace kunv = 0 if denomkunv == 0

/// Label variable
label var kunv "UN voting record k-similarity"


* Generate Scott's Pi based on squared distance metric
*****************************************************

/// Generate pi denominator
generate denompiunv = ss1+ss2 - (s1+s2)^2/(nobs*2)

/// Label variable
label var denompiunv "Pi denominator (squared distances, UN voting record)"

/// Generate chance-correct pi scores
generate piunv = 1-(ssd/denompiunv) if denompiunv != 0
replace piunv = 0 if denompiunv == 0

/// Label variable
label var piunv "Scott's Pi (squared distances, UN voting record)"

 
* Save dataset
*************
/// Generate dyad ID 
gen udyadid =min(ccode1, ccode2)*1000+max(ccode1,ccode2)
order udyadid 

/// Drop self-referencing dyads
drop if ccode1 == ccode2

/// Save
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\UN Voting Record\e-Similarity Measures\scss-0102a-simunv-e-simm.dta", replace


* Close Log *
***********
log close
exit