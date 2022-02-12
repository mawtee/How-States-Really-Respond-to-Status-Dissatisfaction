* Open log *
************
capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\02-Controls & Components\g-Power classification\scss-0102g-pclass", replace

* Programme: scss-0102g-pclass.do
* Project: How States Really Respond to Status Dissatisfaction: a closer look at the material and temporal dynamics of status-driven conflict.
* Author: Matthew Tibbles

**************************************************
* Generate expected status group ranks dataset *
**************************************************

* Description *
***************
* This do-file generates expected status group ranks using annual global ranks of material capabilities.
* Expected status group ranks are based on the following ranking system:
* 1 - World power = 1-3
* 2 - Major power = 4-15
* 3 - Middle power = 16-40
* 4 - Small state =  <40

* Classification for groups ranks above small power require that a country meet the given rank threshold for at least 5 consecutive years
* either as part of a running spell or previous spell. The purpose of this design is to fillter out "outlier" years in which a given country
* experiences a sudden but short-lived boost in material capabilities as a result of, for example, civillian mobilisation.

* Additionally, all group ranks are adjusted for "transition" years, which represent either the 5 year spell before the year in which a country moves to a higher expected
* status rank (upward transition) OR the 5 year spell after the year in which a country moves to a lower expected status rank (downward transition). 
* For upwards transition years, a country is attributed the rank which is given in t+5. For downward transition years, a country is attributed the rank which it
* is given in t-5. The purpose of this design is to account for temporal differences between a country's perception of self and how it is percieved by other countries.
* A rising middle power will see itself as a major power (and thus behave like a major power) before other countries recognise it as such.
* A fading major power will continue to see itself as a major power (and thus behave like major power) despite being recognised by other countries as a middle power. 

* Set up Stata environment *
****************************
version 17
macro drop _all 
capture log close 
clear all 
drop _all 
set linesize 255

* Required packages
local packages tsspell 
foreach p in `packages' {
    capture `p'
    if _rc {
        ssc install `p'
    }
}

* Generate base expected status group ranks
********************************************
// Load monadic system membership dataset
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-symemmon.dta", clear

// Merge with material capabilities dataset
rename ccode ccode1
merge 1:1 ccode year using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\b-Expected Status\scss-0101b-expsts-a-pw.dta", keep (match master) keepusing(expgblsts) nogen

// Drop redundant years
drop if year < 1949 | year > 2000

// Declare time series format
tsset ccode year

// Generate spell information if rank is between 1 and 15 on material capabilities
tsspell, cond(expgblstspw <= 15)

// Rename variav
foreach var of varlist _seq _spell _end {
	rename `var' `var'_maj
}
		
// Calculate spell length
egen splength_maj = max(_seq_maj), by(ccode _spell_maj)

/// Generate major power qualification indicator for spells of at least 5 years 
gen maj_base = 1 if splength_maj >= 5 & splength_maj != .

/// Generate past major power indicator (carrying forward major power qualification indicator to all years after initial qualification spell)
by ccode: carryforward maj_base, gen(maj_past)

/// Generate revised base major power indicator including years in which state is top 25 but year is not part of 5 year spell
gen maj_2 = 1 if maj_past == 1 & splength_maj >= 1 & splength_maj != .

/// Check major powers spells lasting from between 1 and 4 years but without prior 5 year spelll
*| That is, states not designated major powers status despite being ranked in top 25 on material capabilities (accounting, in theory, for sudden militarization).
tab cabb if splength_maj >= 1 & splength_maj <= 4 & maj_2 != 1


* Generate revised major power indicator accounting for rising and fading power spells
**************************************************************************************

/// Generate 1/5 year lags/leads of major power indicator 
forvalues i = 1/5 {
	by ccode: gen maj_2_lg`i' = maj_2[_n - `i'] 
	by ccode: gen maj_2_ld`i' = maj_2[_n + `i'] 
}


/// Generate fully adjusted major power indicator
gen major = maj_2
*| Recode rising/fading power spells as major power spells
foreach maj of varlist maj_2_lg1-maj_2_ld5 {
	replace major = 1 if inlist(`maj', 1)
}

replace major = 0 if major != 1

Middle Powers
*************************************************************************************************************************
/// Generate spell information if rank is between 16 and 40 on material capabilities
tsspell, cond(expgblstspw >= 16 & expgblstspw <= 40)

foreach var of varlist _seq _spell _end {
	rename `var' `var'_mid
}
	
	
/// Calculate spell length
egen splength_mid = max(_seq_mid), by(ccode _spell_mid)

/// Generate middle power qualification indicator for spells of at least 5 years (or where state does does not qualify for major power spell but is <= 20 on global power rank)
gen mid_base = 1 if splength_mid >= 5 & splength_mid != . | expgblstspw <= 15 & major != 1

/// Generate past middle power indicator (carrying forward mmiddle power qualification indicator to all years after initial qualification spell)
by ccode: carryforward mid_base, gen(mid_past)

/// Generate revised middle power indicator including years in which state is 21-40 but year is not part of 5 year spell but has had 5 year spell
gen mid_2 = 1 if mid_past == 1 & splength_mid >= 1 & splength_mid != .

/// Check major powers spells lasting from between 1 and 4 years but without prior 5 year spelll
*| That is, states not designated middle powers status despite being ranked in top 25 on material capabilities (accounting, in theory, for sudden militarization).
tab cabb if splength_mid >= 1 & splength_mid <= 4 & mid_2 != 1


* Generate revised middle power indicator accounting for rising and fading power spells
**************************************************************************************

/// Generate 1/5 year lags/leads of major power indicator 
forvalues i = 1/5 {
	by ccode: gen mid_2_lg`i' = mid_2[_n - `i'] 
	by ccode: gen mid_2_ld`i' = mid_2[_n + `i'] 
}

/// Generate fully adjusted major power indicator
gen middle = mid_2 
*| Recode rising/fading power spells as major power spells
foreach mid of varlist mid_2_lg1-mid_2_ld5 {
	replace middle = 1 if inlist(`mid', 1)
}



replace middle = 0 if major == 1

replace middle = 0 if middle != 1

World
****************************************************************************************************************
/// Generate spell information if rank is between 1 and 3 on material capabilities
tsspell, cond(expgblstspw >= 1 & expgblstspw <= 3)

foreach var of varlist _seq _spell _end {
	rename `var' `var'_wor
}
	
	
/// Calculate spell length
egen splength_wor = max(_seq_wor), by(ccode _spell_wor)

/// Generate world power qualification indicator for spells of at least 5 years (or where state does does not qualify for major power spell but is <= 20 on global power rank)
gen wor_base = 1 if splength_wor >= 5 & splength_wor != . 

/// Generate past world power indicator (carrying forward mmiddle power qualification indicator to all years after initial qualification spell)
by ccode: carryforward wor_base, gen(wor_past)

/// Generate revised middle power indicator including years in which state is 1-5 but active spell is less than 5 years but has had 5 previous 5 year spell (assumed to be world power in this year)
gen wor_2 = 1 if wor_past == 1 & splength_wor >= 1 & splength_wor != .

/// Check major powers spells lasting from between 1 and 4 years but without prior 5 year spelll
*| That is, states not designated major powers status despite being ranked in top 25 on material capabilities (accounting, in theory, for sudden militarization).
tab cabb if splength_wor >= 1 & splength_wor <= 4 & wor_2 != 1


* Generate revised world power indicator accounting downwards/upwards transition year (5 years either side)
**************************************************************************************

/// Generate 1/5 year lags/leads of major power indicator 
forvalues i = 1/5 {
	by ccode: gen wor_2_lg`i' = wor_2[_n - `i'] 
	by ccode: gen wor_2_ld`i' = wor_2[_n + `i'] 
}

/// Generate fully adjusted major power indicator
gen world = wor_2 
*| Recode rising/fading power spells as major power spells
foreach wor of varlist wor_2_lg1-wor_2_ld5 {
	replace world = 1 if inlist(`wor', 1)
}


replace major = 0 if world == 1

di "Non qualification - middle powers"
tab cabb if expgblstspw <= 40 & middle != 1 & major != 1 & world != 1
di "Non qualification - major powers"
tab cabb if expgblstspw <= 15 & major != 1 & world != 1
tab middle if expgblstspw <= 15 & major != 1 & world != 1
di "Non qualification - world powers"
tab cabb if expgblstspw <= 3 & world != 1
tab major if expgblstspw <= 3 & world != 1


* Generate small state indicator, label variables and save 
***********************************************************

/// Generate small state indicator
gen small = 0 if (major == 1 | middle == 1 | world == 1)
replace small = 1 if small == .




gen pclass = 1 if small == 1
replace pclass = 2 if middle == 1
replace pclass = 3 if major == 1
replace pclass = 4 if world == 1


local pclass maj mid
local pclassfull major-power middle-power
local lv label var

foreach pc in `pclass' {
	foreach pcf in `pclassfull' {
		`lv' _seq_`pc' "Sequence no. of `pcf' spells"
	    `lv' _spell_`pc' "Count of `pcf' spells"
	    `lv' _end_`pc' "End of `pcf' spell"
	    `lv' splength_`pc' "Length of `pcf' spell"
	    `lv' `pc'_base "Base `pcf' indiciator"
	    `lv' `pc'_past "Past `pcf' indicator"
		`lv' `pc'_2 "Revised `pcf' indicator"
		forvalues i = 1/5 {
			`lv' `pc'_2_lg`i' "`i' year lag of `pc'_2"
			`lv' `pc'_2_ld`i' "`i' year lead of `pc'_2"
		}
	}
}

`lv' major "Major power"
`lv' middle "Middle power"
`lv' world "Super power"
`lv' small "Small state"
`lv' pclass "Power classification"
label define pclass2 1 "Small state" 2 "Middle power" 3 "Major power" 4 "Super power"
label values pclass pclass2



/// Save
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\g-Power Classification\scss-0102g-pclass.dta", replace


* Close Log *
*************
log close
exit



* Add power rank from 1945, to make spells mor waccurate for 1950 onwards (note, particular, that Turkey should not be classified as small state)
*sorted that, already
* Change labelling, 15 mins
* Chnage descriptions/file-name, 15 mins
*check pclass seperation on graph, 20 mins
*table, by tonight.

















