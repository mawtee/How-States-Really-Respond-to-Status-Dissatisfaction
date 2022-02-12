* Open log *
************
capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\01-Status Deficit & MID\b-Expected Status\scss-0101c-defdis" ,replace

*Programme: scss-0101c-defdis.do
*Project: Status Conflict among Small States
*Author: Matthew Tibbles

****************************************************************
* Generate status deficit and chronic dissatisfaction measures *
****************************************************************

* Description *
***************
* This do-file generates community and global measures of status deficit and chronic dissatisfaction.
* Status deficit defined as expected status minus attributed status while chronic dissatisfaction is an indicator variable that equals 1 if a state has below average status deficit in year t and t-9.

* Set up Stata environment *
****************************
version 17
macro drop _all 
capture log close 
clear all 
drop _all 
set linesize 255


* Generate status deficit measures
***********************************
/// Load attributed status dataset
use  "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\e-Attributed Status Measures\scss-0101a-attsts-e-attstsm.dta", clear
drop if year > 2000
rename ccode ccode1 
rename cabb cabb1

/// Merge with expected status datasets
merge 1:1 ccode1 year using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\b-Expected Status\scss-0101b-expsts-a-pw.dta", keep(match master) keepusing(expcomstspw expgblstspw) nogen
merge 1:1 ccode1 year using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\b-Expected Status\scss-0101b-expsts-c-nm.dta", keep(match master) keepusing(expcomstsnm expgblstsnm) nogen
merge 1:1 ccode1 year using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\b-Expected Status\scss-0101b-expsts-d-pwnm.dta", keep(match master) keepusing(expcomstspwnm expgblstspwnm) nogen

/// Generate status deficit measures
gen comstsdefpw = expcomstspw - attcomsts
gen gblstsdefpw = expgblstspw - attgblsts
gen comstsdefnm = expcomstsnm - attcomsts
gen gblstsdefnm = expgblstsnm - attgblsts
gen comstsdefpwnm = expcomstspwnm - attcomsts
gen gblstsdefpwnm = expgblstspwnm - attgblsts

foreach var of varlist comstsdefpw-gblstsdefpwnm {
	replace `var' = `var' *-1
}

* Generate chronic dissatisfaction measures
****************************************************
/// Generate variables to store community deficit means
gen comdefpwav = .
gen comdefnmav = .

/// Store levels of community/year in local macro
levelsof com, local(coml)
levelsof year, local(yrl)

*>> Run the following commands for each community
foreach c in `coml' {
	*>> Run the following commands for each year
	foreach y in `yrl' {
		 *\ Summarise community deficit measure by community year
		 sum comstsdefpw if com == `c' & year == `y'
		 *\ Store community deficit mean 
		 replace comdefpwav = r(mean) if com == `c' & year == `y'
		 *\ Summarise community deficit measure by community year
		 sum comstsdefnm if com == `c' & year == `y'
		 *\ Store community deficit mean
		 replace comdefnmav = r(mean) if com == `c' & year == `y'
	}
}

/// Generate indicator variables for power, normative and power/normative dissatisfaction
sort ccode1 year
by ccode1 year: gen disspw = 1 if comstsdefpw < comdefpwav
replace disspw = 0 if disspw != 1
by ccode1 year: gen dissnm = 1 if comstsdefnm < comdefnmav
replace dissnm = 0 if dissnm !=1
by ccode1 year: gen dissdub = 1 if (comstsdefpw < comdefpwav & comstsdefnm < comdefnmav)
replace dissdub = 0 if dissdub != 1

/// Declare time series
tsset ccode1 year

*>> Run the following commands for values 1/9
forvalues i = 1/9{
	*\ Generate lags of power-based status dissatisfaction
	tempvar disspw_lg`i'
	by ccode1: gen `disspw_lg`i'' = disspw[_n-`i']
	*\ Generate lags of normative-based status dissatisfaction
	tempvar dissnm_lg`i'
	by ccode1: gen `dissnm_lg`i'' = dissnm[_n-`i']
	*\ Generate lags of power/normative-based status dissatisfaction
	tempvar dissdub_lg`i'
	by ccode1: gen `dissdub_lg`i'' = dissdub[_n-`i']
}

*>> Run the following commands for each variable
foreach var of varlist disspw dissnm dissdub {
	*\ Generate chronic dissatisfaction indicator
	gen chron`var' = 1 if `var' == 1 & ``var'_lg1' == 1 & ``var'_lg2' == 1 & ``var'_lg3' == 1 & ``var'_lg4' == 1 & ``var'_lg5' == 1 & ``var'_lg6' == 1 & ``var'_lg7' == 1 & ``var'_lg8' == 1 & ``var'_lg9' == 1 
	replace chron`var' = 0 if chron`var' != 1
}

/// Drop temp vars
forvalues i = 1/9 {
	drop `disspw_lg`i''
	drop `dissnm_lg`i''
	drop `dissdub_lg`i''
}

* Save dataset
*********************************

/// Label variables
label var comstsdefpw "Community status deficit (power based)"
label var gblstsdefpw "Global status deficit (power based)"
label var comstsdefnm "Community status deficit (normative based)"
label var gblstsdefnm "Global status deficit (normative based)"
label var comstsdefpwnm "Community status deficit (power-normative based)"
label var gblstsdefpwnm "Global status deficit (power-normative based)"
label var comdefpwav "Communtiy status deficit mean (power based)"
label var comdefnmav "Comunnity status deficit mean (normative based)"
label var disspw "Community dissatisfaction (power based)"
label var dissnm "Communtiy dissatisfaction (normative based)"
label var dissdub "Community dissatisfaction (power-normative based)"
label var chrondisspw "Chronic dissatisfaction (power based)"
label var chrondissnm "Chronic dissatisfaction (normative based)"
label var chrondissdub "Chronic dissatisfaction (power-normative based) "

/// Save
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\c-Status Deficit & Chronic Dissatisfaction\scss-0101c-defis.dta", replace


* Close Log *
*************
log close
exit















