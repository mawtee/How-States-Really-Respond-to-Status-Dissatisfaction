* Open log *
************

capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\02-Controls & Components\a-Similarity\IGO Joint Membership\scss-0102a-simigo-e-simm", replace

* Programme: scss-0102a-simigo-e-simm.do
* Project: Status Conflict among Small States
* Author: Matthew Tibbles
* Reference note: This programme is a modified transposition of the programme "msim-data11-simmeasures.do" - authored by Frank Haege and accessed at 

*******************************************************
* Calculate similarity measures for alliance portfolio*
*******************************************************

* Description
*************
* This do-file calculates similarity scores for IGO joint memberships using Signorino and Ritter's S, Cohen's Kappa, and Scott's Pi. 
* The inputs for these calculations are the similarity component variables for IGO joint membership.


* Set up Stata *
****************
version 16
clear all
macro drop _all


/// Load appended similarity components dataset 
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\IGO Joint Membership\d-Similarity Components Appended\scss-0102a-simigo-d-compapp.dta", clear


* Generate Signorino & Ritter's S based on squared distance metric
*****************************************************************

/// Generate s denomintaor
generate denomsigojm = ((10-1)^2*nobs)/2

/// Label variable
label var denomsigojm "Unweighted S denominator (squared distances, IGO joint membership)"

// Generate unweighted s scores
generate sigojm = 1-(ssd/denoms)

/// Label variable
label var sigojm "Unweighted S (squared distances, IGO joint membership)"


* Generate Cohen's Kappa based on squared distance metric
********************************************************

/// Generate k denomintor
generate denomkigojm = ss1+ss2 - (2/nobs)*s1*s2

/// Label variable
label var denomkigojm "IGO joint membership k-denominator"

/// Generate chanced-corrected kappa scores
generate kigojm = 1-(ssd/denomk)

/// Label variable
label var kigojm "IGO joint membership k-similarity"


* Generate Scott's Pi based on squared distance metric
*****************************************************

/// Generate pi denominator
generate denompiigojm = ss1+ss2 - (s1+s2)^2/(nobs*2)

/// Label variable
label var denompiigojm "Pi denominator (squared distances, IGO joint membership)"

/// Generate chance-correct pi scores
generate piigojm = 1-(ssd/denompi)

/// Label variable
label var piigojm "Scott's Pi (squared distances, IGO joint membership)"



* Save dataset
*************

/// Generate dyad ID 
gen udyadid =min(ccode1, ccode2)*1000+max(ccode1,ccode2)
order udyadid 

/// Drop self-referencing dyads
drop if ccode1 == ccode2

/// Save
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\IGO Joint Membership\e-Similarity Measures\scss-0102a-simigo-e-simm.dta" ,replace


* Close Log *
***********
log close
exit