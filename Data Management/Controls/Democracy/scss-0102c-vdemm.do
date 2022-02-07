* Open log *
************
capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\02-Controls & Components\c-V-Dem Measures\scss-0102c-vdemm", replace

***************************************************************
* Generate a directed dyadic dataset of various V-Dem Measures*
***************************************************************

* Programme: scss-0102c-vdemm.do
* Project: Status Conflict among Small States
* Author: Matthew Tibbles

* Description *
***************
* This do-file generates a directed dyadic dataset of V-Dem Measures between 1949 and 2000
* The following measures are extracted from the V-Dem dataset: Elecotral democracy index, Joint democracy indicator and Political instability indicator 


* Set up Stata *
****************
version 16
clear all
macro drop all
set linesize 90


* Generate a directed dyadic version of the monadic V-Dem core dataset
********************************************************************

/// Load V-Dem dataset
import delimited "Status Conflict among Small States\Data Analysis\Datasets\Source\V-Dem\Country_Year_V-Dem_Core_CSV_v10\V-Dem-CY-Core-v10.csv", clear

/// Drop redundant observations
drop if year < 1949 | year > 2000

/// Drop redundant variables
keep year cowcode v2x_polyarchy v2x_regime

/// Rename variables
rename cowcode ccode1
rename v2x_polyarchy demind1
rename v2x_regime regtype1

/// Drop non-system members
drop if ccode1 == .
sort year ccode1

/// Preserve dataset in memory
preserve

/// Rename variables
rename ccode1 ccode2
rename demind1 demind2
rename regtype1 regtype2
 
/// Create and save temporary file
tempfile copy
save `copy'

/// Restore preserved dataset
restore
 
/// Join with temporary file
joinby year using `copy'

/// Drop self-referencing dyads
drop if ccode1 == ccode2

// Drop redundant variables
drop demind2
rename demind1 demind

 /// Generate directed dyad ID
gen ddyadid = (ccode1*1000) + ccode2
order ddyadid
sort ddyadid year

/// Re-sort dataset and re-order variables
sort year ccode1 ccode2
order ddyadid ccode1 ccode2 year demind regtype1 regtype2
 


* Generate V-Dem measures using regime indicator
************************************************

/// Generate joint democracy variable 
gen jointdem = 1 if regtype1 >=2 & regtype2 >= 2
replace jointdem = 0 if jointdem != 1

* Save as stata dataset
***********************

/// Generate dyad ID 
gen udyadid =min(ccode1, ccode2)*1000+max(ccode1,ccode2)
order udyadid, after(ddyadid)

/// Label variables
label var ddyadid "Directed dyad ID"
label var udyadid "Undirected dyad ID"
label var ccode1 "COW country code 1"
label var ccode2 "COW country code 2"
label var year "Year"
label var demind "Electoral democracy index"
label var regtype1 "Regime type 1"
label def regtype1a 0 "Liberal democracy" 1 "Electoral democracy" 2 "Electoral autocracy" 3 "Closed autocracy"
label val regtype1 regtype1a
label var regtype2 "Regime type 2"
label def regtype2a 0 "Liberal democracy" 1 "Electoral democracy" 2 "Electoral autocracy" 3 "Closed autocracy"
label val regtype2 regtype2a
label var jointdem "Joint democracy"


/// Save
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\c-V-Dem Measures\scss-0102c-vdemm.dta", replace


* Close Log *
*************

log close
exit


* check and correct coding scheme, keep polyarchy var, gen joint polyarchy and gen political instability
* cow peace years, cubic splines (basically done, just follow signorino's code')
* save relevant papers (and re-set google drive and mendeley)
* monadic var for country-year data and mi models
* small state var (done)
* done
