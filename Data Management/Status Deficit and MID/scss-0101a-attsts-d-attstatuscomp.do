* Open log *
************
capture log close
log using "Data Analysis\Replication Files\Stata Log Files\01-Data Management\01-Status Deficit & MID\a-Attributed Status\scss-0101a-attsts-d-netstatapp" , replace

* Programme: scss-0101a-attsts-d-netstatapp.do
* Project: How States Really Respond to Status Dissatisfaction: a closer look at the material and temporal dynamics of status-driven conflict.
* Author: Matthew Tibbles

****************************************************************
* Appended netstat dataset for calculation of attributed staus *
****************************************************************

* Description *
***************
* This do-file stacks the netstat datasets for the calculation of attributed status.
* The appended dataset is subsequently cleaned and merged with the state system membership dataset with observations for all years between 1940 and 2005.
* Finally, PageRanks are generated for all years using linear interpolation, and community memberships are carried forward using the ssc module carryforward.

* Set up Stata *
****************
version 16
clear all
macro drop all

* Required packages *
*********************
local packages carryforward 
foreach p in `packages' {
    capture `p'
    if _rc {
        ssc install `p'
    }
}


* Append netstat datasets
**************************************************************
// Load netstat dataset for 1940 (first year of observation)
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\c-Network Statistics\scss-0101a-attsts-c-netstat-1940.dta" ,replace

// Run the following commands for each year
foreach year of numlist 1950 (5) 2005 {
    
    *|Append remaining years     
    append using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\c-Network Statistics\scss-0101a-attsts-c-netstat-`year'.dta"
}


* Remove arbitrarily low PageRanks resulting from singular community membership due to zero in-links
********************************************************************************************************************************************
// Identify possible noise
bysort year com: gen comsize = _N
list if comsize == 1
count if comsize == 1
*| 32 cases of singular community memberships across 5 recorded years (1940 1960 1965 1970 1975)
bysort year: egen minpagerank = min(pagerank)
count if comsize == 1 & pagerank == minpagerank
*| All 32 singular community cases have the lowest possible PageRank in year of observation

// Recode noisy observations as missing values for both community and pagerank
replace com = . if comsize == 1
replace pagerank = . if comsize == 1
replace comsize = . if comsize == 1

// Generate minimum community size variable to check for other potentially noisy observations
bysort year: egen mincom = min(comsize)
tab mincom year
bysort mincom year: gen unique = _n == 1
sum mincom if unique
display r(mean)
*| Communities look to be appropiately sized: across all years average size of smallest community is 26.46
tab year cabb if comsize == r(min)
*| Minimum community size across all recorded years is 6 in 1965
*| AUL
*| MAL
*| NEW
*| PHI
*| RVN
*| THI
*| Community is compromised of states situated in or around or south east Asia 

// Drop redundant variables
drop comsize minpagerank mincom unique

// Save
sort year ccode
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\d-Network Statistics Appended\scss-0101a-attsts-d-netstatapp.dta" ,replace

* Merge appended dataset with monadic state system membership dataset to generate observations for all years between 1940 and 2005
*********************************************************************************************************************************
// Load state system membership dataset
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-symemmon.dta" ,clear

// Merge with appended netstat dataset
merge 1:1 ccode year using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\d-Network Statistics Appended\scss-0101a-attsts-d-netstatapp.dta"

// Review merge
tab _m
*| not matched (1) =  6939
*| matched (3) = 1785
tab year if _m == 1
*| All unmatched observations occur on years not recorded by netstat datasets 
drop _m


* Interpolate PageRanks for all years and carry forward community memberships
*****************************************************************************
// Interpolate PageRanks by year
by ccode: ipolate pagerank year, gen(ipagerank)
replace pagerank = ipagerank
drop ipagerank

// Carry forward community memberships for missing years
bysort ccode: carryforward com, gen(com2)
replace com = com2
drop com2

// Drop missing values and redundant observations
drop if pagerank == .
drop if year <1949

/// Save
order com pagerank, after(year) 
sort year ccode
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\d-Network Statistics Appended\scss-0101a-attsts-d-netstatapp.dta" ,replace


* Close log *
*************
log close
exit

