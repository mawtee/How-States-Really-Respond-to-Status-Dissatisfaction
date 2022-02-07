* Open log *
************
capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\02-Controls & Components\b-Trade Dependence\scss-0102b-tdep", replace

*******************************************************
* Generate a directed dyadic trade dependence dataset *
*******************************************************

* Programme: scss-0102b-tdep.do
* Project: Status Conflict among Small States
* Author: Matthew Tibbles

* Description *
***************
* This do-file generates a directed dyadic dataset of trade dependence measures for all states between 1959 and 2000
* The input data for this measure is taken from the Gleditsch GDP and the COW trade datasets, and then converted into 2000 constant US $ using the US Bureau of National Statistics (USBNS) Consumer Price Index (CPI)
* Trade dependence equals bilateral dyadic trade as a proportion of gdp


* Set up Stata *
****************
version 16
clear all
macro drop all
set linesize 90


* Load CPI data, generate average annual CPI variable and save as stata datasets
********************************************************************************

/// Load dataset
insheet using "Status Conflict among Small States\Data Analysis\Datasets\Source\Consumer Price Index - USBNS\cpi_usbns_urb_all.txt", clear

/// Keep only main series (CUSR0000SA0 - All items in U.S. city average, all urban consumers, seasonally adjusted)
keep if series_id == "CUSR0000SA0"

/// Drop redundant observations  
drop if year < 1949 | year > 2000

/// Drop redundant variable
drop footnote_codes

/// Generate cpi averge annual value 
gen cpiannav = .

foreach y of numlist 1949/2000 {
    
    sum value if year == `y', meanonly

replace cpiannav = r(mean) if year == `y'

}

/// Keep only one record for each year
duplicates drop year , force
drop period value

/// Label variables
label var series_id "All items in U.S. city average, all urban consumers, seasonally adjusted"
label var year "Year"
label var cpiannav "Consumer Price Index average annual value"

/// Save dataset
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\b-Trade Dependence\scss-0102b-tdep-a-cpi.dta", replace


* Load Gleditsch GDP dataset, calculate total GDP and save as sata dataset
**************************************************************************

/// Load dataset
insheet using "Status Conflict among Small States\Data Analysis\Datasets\Source\GDP - Gleditsch v.6\gdpv6.txt", clear

/// Drop redundant observations
drop if year < 1949 | year > 2000

/// Drop redundant variables
drop realgdp rgdppc origin 

/// Convert current gdp per capita into total gdp 
bysort statenum year: gen cgdp = cgdppc * pop 

/// rename variables 
rename statenum ccode1
rename stateid cabb1

/// Label variables
label var ccode1 "COW country code 1"
label var cabb1 "COW country abbreviation 1"
label var year "Year"
label var pop "Population"
label var cgdppc "GDP per capita - current US $"
label var cgdp "Total GDP - current US $"

/// Save dataset
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\b-Trade Dependence\scss-0102b-tdep-b-gdp.dta", replace


* Merge system membership dataset with trade dependence input datasets 
***********************************************************************

/// Load directed dyadic system dataset
import delimited "Status Conflict among Small States\Data Analysis\Datasets\Source\COW_Trade_4.0\COW_Trade_4.0\National_COW_4.0.csv", clear

/// Drop redundant observations (no trade data after 2000)
drop if year < 1950 | year > 2000

/// Total trade variable
gen tottrade = imports+exports

/// Drop redundant variables
keep ccode year tottrade
rename ccode ccode1

/// Merge with gdp data
merge 1:1 ccode1 year using  "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\b-Trade Dependence\scss-0102b-tdep-b-gdp.dta", keepusing(cabb1 cgdp) keep(match master) nogen
order cabb1, after(ccode1)



/// Merge with cpi data
merge m:1 year using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\b-Trade Dependence\scss-0102b-tdep-a-cpi", keepusing(cpiannav) nogen


* Convert trade figures into 2000 constant US $ and generate measure of trade dependence
****************************************************************************************

/// Generate input variable for 2000 constant US $ conversion 
egen cpi2000 = max(cpiannav)

/// Convert total trade variables to 2000 US $ 
gen tottrade2000 = .
bysort ccode1 year: replace tottrade2000 = tottrade*(cpi2000/cpiannav)

/// Generate real terms gdp figures in 2000 US $
gen gdp2000 = .
bysort ccode1 year: replace gdp2000 = cgdp*(cpi2000/cpiannav)

/// Generate trade openess 
gen tropen2000 = gdp2000/tottrade2000


/// Save
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\b-Trade Dependence\scss-0102b-tdep-c-tdep2000.dta", replace
















/// Generate trade dependence in 2000 constant US $
bysort ddyadid year: gen trdep2000 = gdp2000/tbitr2000

// Generate gdp per capita in 2000 constant US $ (for use in multiple imputation models)
gen gdppc2000 = .
bysort ccode1 year: replace gdppc2000 = cgdppc*(cpi2000/cpiannav)

* REORDER VARS************************************************************
order gdppc2000, after(gdp2000)


* Save as stata dataset
**********************
/// Label variables
label var cpi2000 "Consumer price index 2000 average"
label var tbitr2000 "Total bilateral trade 2000 US $"
label var gdp2000 "Total GDP 2000 US $"
label var gdppc2000 "GDP per capita 2000 US $"
label var tbitr2000 "Total bilateral trade 2000 US $"
label var gdp2000 "Total GDP 2000 US $"
label var trdep2000 "Trade dependence 2000 US $"
label var gdppc2000 "GDP per capita 2000 US $"

/// Save
sort ccode1 ccode2 year
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\b-Trade Dependence\scss-0102b-tdep-c-tdep2000.dta", replace


* Close log *
*************
 log close
 exit


