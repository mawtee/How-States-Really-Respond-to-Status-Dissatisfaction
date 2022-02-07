* Open log * 
************
capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\02-Controls & Components\a-Similarity\UN Voting Record\scss-0102a-simunv-b-smat", replace


*****************************************************
* Generate roll call UN voting record soci-matrices *
*****************************************************

* Programme:	scss-0102a-simunv-b-smat.do
* Project:		Status Conflict among Small States
* Author:		Matthew Tibbles

* Description
*************
* This do-file reshapes the UN voting record dataset (msim-data05-voterecord.dta) into wide format.
* It generates datasets in the form of valued roll call vote affiliation-matrices for individual years and the entire time period.


* Set up Stata
**************
version 16
clear all
macro drop _all
set linesize 80
set more off


* Recode vote type varibale weights
************************************
// Load dataset 
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\UN Voting Record\a-Cleaned Monadic\scss-0102a-simunv-a-cleanmon.dta", clear
 
/// Generate recoded vote type variable
generate votetypew = .
replace votetypew = 1 if votetype == 3
replace votetypew = 2 if votetype == 2 | votetype == 8
replace votetypew = 3 if votetype == 1
* Absenteism is equivalent to abstaining
note votetypew: 'Absent' is recoded as'Abstain'

/// Recode remaining missing values as Abstain (2)
replace votetypew = 2 if votetype == .
*| Having dropped non-members, it is assumed that remaining missing values represent unverified cases of Absentiesm

/// Label variable
label var votetypew "Type of vote (weighted)"
label def votetypew2 1 "No" 2 "Abstain" 3 "Yes"
label val votetypew votetypew2

/// Compare coding schemes
tab votetype 
tab votetypew

/// Drop original vote type variable
drop votetype ccode


* Generate a roll call vote type socio-matrix for each year
************************************************************
*~ Run the following commands for each year 
foreach x of numlist 1949/1963 {
	/// Keep the full dataset in memory while transforming the data for individual years
	preserve

	/// Reshape the data for the respective year into wide format
	drop if year != `x'
	reshape wide votetypew, i(rccode) j(cabb) string

	/// Delete 'votetype' from variable names and labels
	unab vars : votetypew*
	local a : subinstr local vars "votetypew" "", all
	foreach y of local a {
		label var votetypew`y' `y'
	}
	
	foreach y of local a {
		rename votetypew`y' `y'
	
	}

	/// Save the roll call vote type socio-matrix for the respective year
	order session rccode rccode_orig unres date day month year
	sort rccode
	compress
	save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\UN Voting Record\b-Socio-Matrices\scss-0102a-simunv-b-smat-`x'.dta", replace

	restore

}


*~ Run the following commands for each year (no votes in 1964)
foreach x of numlist 1965/2000 {
	

	///Keep the full dataset in memory while transforming the data for individual years
	preserve

	////Reshape the data for the respective year into wide format
	drop if year != `x'
	reshape wide votetypew, i(rccode) j(cabb) string

	////Delete 'votetvalued from variable names and labels
	unab vars : votetypew*
	local a : subinstr local vars "votetypew" "", all
	foreach y of local a {
		label var votetypew`y' `y'
	}
	foreach y of local a {
		rename votetypew`y' `y'
	}

	////Save the  roll call vote by country affiliation matrixfor the respective year
	order session rccode rccode_orig unres date day month year
	sort rccode
	compress
	save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\UN Voting Record\b-Socio-Matrices\scss-0102a-simunv-b-smat-`x'.dta", replace

	restore

}



* Close Log *
*************
log close
exit