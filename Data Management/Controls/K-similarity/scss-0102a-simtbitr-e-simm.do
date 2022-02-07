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
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\Total Bilateral Trade\d-Similarity Components Appended\scss-0102a-simtbitr-d-compapp.dta", clear

/// Drop dyads that did not trade with the same state in a year
drop if nobs == 0

* Generate Signorino & Ritter's S based on squared distance metric
*****************************************************************

/// Generate s denomintaor
generate denomstbitr = ((10-1)^2*nobs)/2

/// Label variable
label var denomstbitr "Unweighted S denominator (squared distances, total bilateral trade)"

// Generate unweighted s scores
generate stbitr = 1-(ssd/denomstbitr)

/// Label variable
label var stbitr "Unweighted S (squared distances, total bilateral trade)"


* Generate Cohen's Kappa based on squared distance metric
********************************************************

/// Generate k denomintor
generate denomktbitr = ss1+ss2 - (2/nobs)*s1*s2

/// Label variable
label var denomktbitr "Trade k-denominator"

/// Generate chanced-corrected kappa scores
generate ktbitr = 1-(ssd/denomktbitr) if denomktbitr != 0
replace ktbitr = 0 if denomktbitr == 0

/// Label variable
label var ktbitr "Trade k-similarity"


* Generate Scott's Pi based on squared distance metric
*****************************************************

/// Generate pi denominator
generate denompitbitr = ss1+ss2 - (s1+s2)^2/(nobs*2)

/// Label variable
label var denompitbitr "Pi denominator (squared distances, total bilateral trade)"

/// Generate chance-correct pi scores
generate pitbitr = 1-(ssd/denompitbitr) if denompitbitr != 0
replace pitbitr = 0 if denompitbitr == 0

/// Label variable
label var pitbitr "Scott's Pi (squared distances, total bilateral trade)"

 
* Save dataset
*************

/// Generate dyad ID 
gen udyadid =min(ccode1, ccode2)*1000+max(ccode1,ccode2)
order udyadid 

/// Drop self-referencing dyads
drop if ccode1 == ccode2

/// Save
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\Total Bilateral Trade\e-Similarity Measures\scss-0102a-simtbitr-e-simm.dta", replace


* Close Log *
***********
log close
exit