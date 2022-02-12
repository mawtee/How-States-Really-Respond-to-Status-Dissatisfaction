* Open log *
************
capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\02-Controls & Components\d-Joiner Threat\scss-0102d-jnrthreat", replace

* Programme: scss-0102d-jnrthrt.do
* Project: How States Really Respond to Status Dissatisfaction: a closer look at the material and temporal dynamics of status-driven conflict.
* Author: Matthew Tibbles

**************************************************************
* Generate joiner threat measure *
**************************************************************

* Description *
***************

* This do-file generates a bespoke measure of the threat posed by potential joiners to an MID - joiner-threat.
* Joiner threat equals the sum of the material capabilities (CINC) of side 2's defensive allies and contiguous neighbours.

* Set up Stata environment *
****************************
version 17
macro drop _all 
capture log close 
clear all 
drop _all 
set linesize 255

* Clean system membership and contiguity datasets
*******************************************************
* System membership
*--------------------------
// Load directed dyadic system membership dataset
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-symemddyadsr.dta", clear

// Drop self-referencing dayds
drop if ccode1 == ccode2

* Contiguity
*----------------------------------------------------------
// New frame
frame create con
frame change con

// Load contiguity dataset
import delimited "Status Conflict among Small States\Data Analysis\Datasets\Source\DirectContiguity320\contdird.csv", clear

// Drop redundant observations/variables
drop if year < 1949 | year > 2000
keep state1no state2no year conttype

// Drop duplicate observations, keeping highest (lowest) level of contiguity by dyad-year 
bysort state1no state2no year: egen maxcontig = min(conttype)
duplicates tag state1no state2no year, gen(dup)
drop if dup != 0 & conttype != maxcontig
duplicates drop state1no state2no year, force
drop maxcontig dup

// Recode contiguity as binary variable (1 = contiguous by land or seperated by no more than 24miles of water
*| Coding reflects the maximum distance at which two states'12-mile territorial limits can intersect
replace conttype = 0 if conttype > 3 
replace conttype = 1 if conttype == 2 | conttype == 3

// Rename variables
rename state1no ccode1
rename state2no ccode2
rename conttype contig

// Generate directed dyadic contigutiy dataset (via merge with system membership)
frame change default
frlink 1:1 ccode1 ccode2 year, frame(con)
frget contig, from(con)
replace contig = 0 if contig == .
drop con
frame drop con

* Recode ATOP alliance dataset and merge with contiguity data
***************************************************************
// New frame
frame create ally
frame change ally

// Load alliance data
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-atypeddyad.dta", clear

// Keep only defensive alliance records
drop if atype < 3

// Rename variables
rename ccode1 ccode2x
rename ccode2 ccode1
rename ccode2x ccode2
rename atype defally_2to1

// Add to contiguity frame
frame change default
frlink 1:1 ccode1 ccode2 year, frame(ally)
frget defally_2to1, from(ally)
drop ally
frame drop ally

* Merge capabilities data with contiguity-alliance data
*-----------------------------------
// New frame
frame create mcapp
frame change mcapp

// Load capabilities data
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\b-Expected Status\scss-0101b-expsts-a-pw.dta", clear

// Rename to facilitate merge
rename ccode ccode2

/// Add to contigutiy-alliance frame
frame change default
frlink m:1 ccode2 year, frame(mcapp)
frget mcap, from(mcapp)
rename mcap mcap_2
drop mcapp
frame drop mcapp

* Calculate joiner threat 
*************************************
// Generate potential joiner indicator var
gen potenjnr = .

// Run the following commands for each year
foreach yr of numlist 1949/2000 {
    
    /// Run the following command for each country
    levelsof ccode1, local(levels) 
    foreach l in `levels'{
	    
	*| Tag potential joiners (contiguous defensive allies of country i)
	 replace potenjnr = 1 if year == `yr' & ccode1 == `l' & (defally_2to1 == 3 | contig == 1)
	    
    }
}
		
// Generate joiner threat variable (sum of CINC across country i's contigiuous defensive allies)
bysort ccode1 year: egen jnrthreat = total(mcap_2) if potenjnr == 1

// Fill dyad gaps for non-missing values (where country j is not contigious defensive ally)
bysort ccode1 year (jnrthreat): replace jnrthreat = jnrthreat[1] if missing(jnrthreat)

// Recode missing values as 0 (where country i has zero contiguous defensive allies)
replace jnrthreat = 0 if jnrthreat == .

// Label variables
label var contig "Contiguous, by land or no more than 24 miles of water"
label var defally_2to1 "Defensive ally (ccode2 to ccode1)"
label var potenjnr "Potential joiner"
label var jnrthreat "Joiner threat"

// Save
sort ccode1 ccode2 year
compress 
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\d-Joiner Threat\scss-0102d-jnrthreat.dta", replace


* Close Log *
*************
log close
exit


    






