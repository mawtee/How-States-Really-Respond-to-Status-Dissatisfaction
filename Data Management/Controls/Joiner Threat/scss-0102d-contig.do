* Open log *
************
capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\02-Controls & Components\d-Contiguity\scss-0102d-contig", replace

*****************************************************
* Generate a dyadic dataset for contiguity *
*****************************************************

* Programme: scss-0102d-contig.do
* Project: Status Conflict among Small States
* Author: Matthew Tibbles

* Description *
***************
* This do-file generates an undirected dyadic dataset for contiguit using the COW Direct Contiguity dataset v3.2
 

* Set up Stata *
****************
version 16
clear all
macro drop all
set linesize 90

* Load dataset and generate contiguous indicator
************************************************

/// Load dataset
import delimited "Status Conflict among Small States\Data Analysis\Datasets\Source\DirectContiguity320\contdird.csv", clear

/// Drop redundant observations/variables
drop if year < 1949 | year > 2000
keep state1no state2no year conttype

/// Drop duplicate observations, keeping highest (lowest) level of contiguity by dyad-year 
bysort state1no state2no year: egen maxcontig = min(conttype)
duplicates tag state1no state2no year, gen(dup)
drop if dup != 0 & conttype != maxcontig
duplicates drop state1no state2no year, force
drop maxcontig dup

/// Recode contiguity as binary variable where 1 = contiguous by land or seperated by no more than 24miles of water - reflecting the maximum distance at which two states'12-mile territorial limits can intersect)
replace conttype = 0 if conttype > 3 
replace conttype = 1 if conttype == 2 | conttype == 3

* Save as stata dataset
*************************

/// Rename variables
rename state1no ccode1
rename state2no ccode2
rename conttype contig

/// Generate dyad ID 
gen udyadid =min(ccode1, ccode2)*1000+max(ccode1,ccode2)
order udyadid 

/// Label variables
label var udyadid "Undirected dyad ID"
label var ccode1 "COW country code1"
label var ccode2 "COW country code2"
label var year "Year"
label var contig "Contiguous, by land or no more than 24 miles of water"

/// Save
compress 
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\d-Contiguity\scss-0102d-contig.dta", replace


* Close Log *
*************

log close
exit

