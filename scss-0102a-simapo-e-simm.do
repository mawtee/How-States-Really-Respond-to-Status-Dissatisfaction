* Open log *
************

capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\02-Controls & Components\a-Similarity\Alliance Portfolio\scss-0102a-simapo-e-simm", replace

* Programme: scss-0102a-simapo-e-simm.do
* Project: Status Conflict among Small States
* Author: Matthew Tibbles
* Reference note: This programme is a modified transposition of the programme "msim-data11-simmeasures.do" - authored by Frank Haege and accessed at 

*******************************************************
* Calculate similarity measures for alliance portfolio*
*******************************************************

* Description
*************
* This do-file calculates similarity scores for alliance portfolios using Signorino and Ritter's S, Cohen's Kappa, and Scott's Pi. 
* The inputs for these calculations are the similarity component variables generated for alliance portfolio.


* Set up Stata *
****************
version 16
clear all
macro drop _all


/// Load appended similarity components dataset 
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\Alliance Portfolio\d-Similarity Components Appended\scss-0102a-simapo-d-compapp.dta"  ,clear


* Generate Signorino & Ritter's S based on squared distance metric
*****************************************************************

/// Generate s denomintaor
generate denomsapo = ((3-0)^2*nobs)/2

/// Label variable
label var denoms "Unweighted S denominator (squared distances, alliance portfolio)"

// Generate unweighted s scores
generate sapo = 1-(ssd/denoms)

/// Label variable
label var sapo "Alliance portfolio s-similarity"


* Generate Cohen's Kappa based on squared distance metric
********************************************************

/// Generate k denomintor
generate denomkapo = ss1+ss2 - (2/nobs)*s1*s2

/// Label variable
label var denomkapo "Alliance portolio k-denominator"

/// Generate chanced-corrected kappa scores
generate kapo = 1-(ssd/denomk)

/// Label variable
label var kapo "Alliance portfolio k-similarity"


* Generate Scott's Pi based on squared distance metric
*****************************************************

/// Generate pi denominator
generate denompiapo = ss1+ss2 - (s1+s2)^2/(nobs*2)

/// Label variable
label var denompiapo "Pi denominator (squared distances, alliance portfolio)"

/// Generate chance-correct pi scores
generate piapo = 1-(ssd/denompi)

/// Label variable
label var piapo "Scott's Pi (squared distances, alliance portfolio)"


* Save dataset
*************

/// Generate dyad ID 
gen udyadid =min(ccode1, ccode2)*1000+max(ccode1,ccode2)
order udyadid 

/// Drop self-referencing dyads
drop if ccode1 == ccode2

/// Save
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\Alliance Portfolio\e-Similarity Measures\scss-0102a-simapo-e-simm.dta" ,replace


* Close Log *
***********
log close
exit