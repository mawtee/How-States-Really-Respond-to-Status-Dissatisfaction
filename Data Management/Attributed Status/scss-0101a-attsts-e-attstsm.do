 *Open log *
************
capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\01-Status Deficit & MID\a-Attributed Status\scss-0101a-attsts-e-attstsm" ,replace

*Programme: scss-0101a-attsts-e-attstsm.do
*Project: Status Conflict among Small States
*Author: Matthew Tibbles

***************************************
* Generate attributed status measures *
***************************************

* Description *
***************
* This do file generates community, regional and global measures of attributed status using standardized values of field-ranked PageRank scores.
* In the process, community, regional and global status ranks are also generated, the latter of which is used as the outcome variable for INSERT.


* Set up Stata *
****************
version 16
clear all
macro drop all



* Obtain COW regional codes
***************************

/// Load COW home region data 
import delimited "Status Conflict among Small States\Data Analysis\Datasets\Source\COW Regional Classification\cowreg-eugene.csv", clear

// Save as stata dataset
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\cowreg.dta", replace

/// Load appended network statistics dataset
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\d-Network Statistics Appended\scss-0101a-attsts-d-netstatapp.dta" ,clear

/// Merge with COW region dataset
merge 1:1 ccode year using "Status Conflict among Small States\Data Analysis\Datasets\Source\cowreg.dta", keep(match master) keepusing(region1) nogen

/// Rename and label variable
rename region1 reg
label var reg "COW region"
label define reg2  1 "Europe" 2 "Middle East" 3 "Africa" 4 "Asia" 5 "Americas"
label values reg reg2
order reg, after(com)

* Generate attributed status variables
**************************************

/// Field-rank by year community
bysort year com: egen attcomsts  = rank(pagerank), field

/// Field-rank by year region
bysort year reg: egen attregsts  = rank(pagerank), field

/// Field-rank by year
bysort year: egen attgblsts = rank(pagerank), field


* Save dataset
*****************

/// Label variables
label var attcomsts "Attributed community status"
label var attregsts "Attributed regional status"
label var attgblsts "Attributed global status"

/// Save
sort year ccode
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\e-Attributed Status Measures\scss-0101a-attsts-e-attstsm.dta" ,replace


* Close Log *
*************
log close
exit

