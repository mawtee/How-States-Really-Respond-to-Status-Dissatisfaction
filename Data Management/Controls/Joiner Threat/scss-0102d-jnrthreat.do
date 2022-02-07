* Open log *
*----------*

capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\02-Controls & Components\d-Joiner Threat\scss-0102d-jnrthreat", replace

**************************************************************
* Generate joiner threat measure *
**************************************************************

* Programme: scss-0102d-jnrthrt.do
* Project: Status Conflict among Small States
* Author: Matthew Tibbles

* Description *
*-------------*

* This do-file generates a measure of the threat posed by potential joiners to an MID.
* Joiner threat equals the sum of the material capabilities (CINC) of side 2's defensive allies and contiguous neighbours.

* Set up Stata *
*--------------*
version 17
clear all
macro drop all
set linesize 90


/// Load directed dyadic system membership dataset
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-symemddyadsr.dta", clear

drop if ccode1 == ccode2


* Load contiguity dataset and generate contiguous indicator
*----------------------------------------------------------

frame create con
frame change con
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

/// Recode contiguity as binary variable (1 = contiguous by land or seperated by no more than 24miles of water
*| Coding reflects the maximum distance at which two states'12-mile territorial limits can intersect
replace conttype = 0 if conttype > 3 
replace conttype = 1 if conttype == 2 | conttype == 3

/// Rename variables
rename state1no ccode1
rename state2no ccode2
rename conttype contig


frame change default
frlink 1:1 ccode1 ccode2 year, frame(con)
frget contig, from(con)
replace contig = 0 if contig == .
drop con
frame drop con

* Recode alliance data and merge with contiguity dataset
*------------------------------------------------------

/// Create alliance frame
frame create ally
frame change ally

/// Load alliance data
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-atypeddyad.dta", clear

/// Keep only defensive alliance records
drop if atype < 3

rename ccode1 ccode2x
rename ccode2 ccode1
rename ccode2x ccode2
rename atype defally_2to1

/// Merge frames
frame change default
frlink 1:1 ccode1 ccode2 year, frame(ally)
frget defally_2to1, from(ally)
drop ally
frame drop ally

* Merge capabilities data
*-----------------------------------

/// Create capabilities frame
frame create mcapp
frame change mcapp

/// Load capabilities data
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\b-Expected Status\scss-0101b-expsts-a-pw.dta", clear

/// Rename to facilitate merge
rename ccode ccode2

/// Merge frames
frame change default
frlink m:1 ccode2 year, frame(mcapp)
frget mcap, from(mcapp)
rename mcap mcap_2
drop mcapp
frame drop mcapp


* Calculate joiner threat 
*----------------------------------

/// Generate potential joiner indicator var
gen potenjnr = .

*~ Run the following commands for each year
foreach yr of numlist 1949/2000 {
    
	/// Store country codes in macro
	levelsof ccode1, local(levels) 
	    
		*~ Run the following command for each country
		foreach l in `levels'{
	    
		/// Assign value to potential joiners
		replace potenjnr = 1 if year == `yr' & ccode1 == `l' & (defally_2to1 == 3 | contig == 1)
	    
	}
}
		
/// Generate joiner threat variable
bysort ccode1 year: egen jnrthreat = total(mcap_2) if potenjnr == 1

//fill gaps for non-missing values
bysort ccode1 year (jnrthreat): replace jnrthreat = jnrthreat[1] if missing(jnrthreat)

/// recode missing values as 0.
replace jnrthreat = 0 if jnrthreat == .


/// Label variables
label var contig "Contiguous, by land or no more than 24 miles of water"
label var defally_2to1 "Defensive ally (ccode2 to ccode1)"
label var potenjnr "Potential joiner"
label var jnrthreat "Joiner threat"




/// Save
sort ccode1 ccode2 year
compress 
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\d-Joiner Threat\scss-0102d-jnrthreat.dta", replace


* Close Log *
*************

log close
exit


    






