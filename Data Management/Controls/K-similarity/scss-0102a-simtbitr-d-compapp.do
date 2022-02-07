* Open log *
************

capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\02-Controls & Components\a-Similarity\Total Bilateral Trade\scss-0102a-simtbitr-d-compapp" ,replace

* Programme: scss-0102a-simtbitr-d-compapp.do
* Project: Status Conflict among Small States
* Author: Matthew Tibbles
* Reference note: This programme is a modified transposition of the programme "msim-data10-simdata.do" - authored by Frank Haege and accessed at 

**************************************************************************************************************************************************
* Generate appended dataset of component variables for the calculation of total bilateral trade similarity measures across the entire time period *
**************************************************************************************************************************************************

* Description *
**************
* This do-file stacks the yearly directed dyadic datasets of component variables for the calculation of similarity measures for total bilateral trade


* Set up Stata *
****************
version 16
clear all
macro drop _all


* Append yearly component datasets
**********************************

/// Load first yearly component dataset
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\Total Bilateral Trade\c-Similarity Components\scss-0102a-simtbitr-c-comp-1949.dta" ,clear

 
/// Append the remaining yearly datasets
foreach year of numlist 1950/2000 {

    append using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\Total Bilateral Trade\c-Similarity Components\scss-0102a-simtbitr-c-comp-`year'.dta" 

}


* Merge appended dataset with system membership dataset on first first dyad country
******************************************************************************************

/// Rename variables and sort (to facilitate merge on monadic data)
rename cabb1 cabb
sort year cabb

/// Merge
merge m:1 year cabb using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-symemmon.dta", keep(match master) nogen

/// Revert variables names to dyadic format
rename cabb cabb1
rename ccode ccode1


* Merge appended dataset with state system membership data on second dyad country
********************************************************************************

/// Rename variables and sort (to facilitate merge on monadic data)
rename cabb2 cabb
sort year cabb

/// Merge
merge m:1 year cabb using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-symemmon.dta" ,keep(match master) nogen

/// Revert to variable names to dyadic format
rename cabb cabb2
rename ccode ccode2


* Save dataset
***************

/// Generate directed dyad ID 
gen ddyadid  = (ccode1*1000) + ccode2 
order ddyadid year
isid ddyadid year
*| Variables ddyadid year uniquely identify observations

/// Label variables
label var ddyadid "Directed Dyad ID"
label var ccode1 "COW country code 1"
label var ccode2 "COW country code 2"

/// Re-order variables and sort
order ccode1 cabb1 ccode2 cabb2 nobs tnobs, after(year)
sort year ccode1 ccode2

/// Save
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\Total Bilateral Trade\d-Similarity Components Appended\scss-0102a-simtbitr-d-compapp.dta" ,replace


*Close Log*
***********

log close
exit