* Open log *
************
capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\01-Status Deficit & MID\d-Militarized Interstate Disputes\scss-0101d-mid" ,replace

*Programme: scss-0101d-mid.do
*Project: Status Conflict among Small States
*Author: Matthew Tibbles

*************************************************
* Clean and operationalise dyadic MID datatset  *
*************************************************

* Description *
*************
* This do file generates a fully operationalised version of the dyadic mid dataset v3.1 for use in the regressive and distributive modelling of status-disssatissfaction theory.


* Set up Stata *
****************
version 16
clear all
macro drop all


* Load dyadic mid dataset v3.1 
******************************
/// Load dyadic MID datset v3.1
import delimited "Status Conflict among Small States\Data Analysis\Datasets\Source\MID_Dyads_3.1\MID_Dyads_3.1_Moaz.csv" ,clear

/// Drop redundant observations/variables
drop if strtyr < 1950 | strtyr > 2000
keep disno dyindex statea namea stateb nameb strtyr year outcome fatlev hihost rolea roleb war


* Keep only dyadic disputes in which side1 is the primary initiator and side2 is the primary target (variance in the motives and relevance of joiners on both sides is likely to produce an unreliable and distorted picture of an initiating state's motivations and intended target)
****************************************************************************************************************************************************************************
keep if rolea == 1 & roleb == 3


* Keep only the last year of each dyadic dispute (outcomes are listed for last year of dispute only)
****************************************************************************************************
/// Peform stable sort
sort dyindex statea stateb strtyr year

/// Keep if observation number equals total number of observations
by dyindex statea stateb strtyr: keep if _n == _N


* Recode outcomes
********************

/// Victory
replace outcome = 1 if outcome == 4

/// Defeat
replace outcome = 2 if outcome == 3

/// Stalemate
replace outcome = 3 if inlist(outcome, 5, 6 , 7, 8)

/// Recode remaining 0 outcomes as stalemate
replace outcome = 3 if outcome == 0


* Generate additional variables
*******************************
/// Generate MID initiation indicator
gen midint = 1

/// Generate fatal MID indicator
gen fmidint = 1 if fatlev >= 1
replace fmidint = 0 if fmidint != 1

/// Generate directed dyad ID
gen ddyadid = (statea*1000) + stateb


* Identify and drop duplicate observations
*******************************************
duplicates tag ddyadid strtyr, gen(dup)
bysort ddyadid strtyr: egen maxhost = max(hihost)
drop if hihost != maxhost
duplicates drop ddyadid strtyr, force
isid ddyadid strtyr
drop dup maxhost


* Rename variables
******************
rename statea ccode1
rename namea cabb1
rename stateb ccode2
rename nameb cabb2
rename year endyear
rename strtyr year
rename rolea role1
rename roleb role2
rename war warint


* Label variables
*****************
label var disno "Dispute number"
label var dyindex "Dyadic dispute index"
label var ddyadid "Directed dyad ID"
label var ccode1 "COW country code 1"
label var cabb1 "COW country abbreviation 1"
label var ccode2 "COW country code 2"
label var cabb2 "COW country abbreviation 2"
label var year "Year"
label var endyear "End year"
label var outcome "Outcome of dyadic dispute"
label def outcome2 1 "Victory" 2 "Defeat" 3 "Stalemate"
label values outcome outcome2
label var fatl "Fatality level"
label def fatlev2 0 "None" 1 "1-25 deaths" 2 "26-100 deaths" 3 "101-250 deaths" 4 "251-500 deaths" 5 "501-999 deaths" 6 ">999 deaths" -9 "Unclear"
label values fatlev fatlev2 
label var hihost "Highest level of hostility in dyadic dispute" 
label def hihost2 1 "None" 2 "Threat to use force" 3 "Display of force" 4 "Use of force" 5 "Interstate war"
label val hihost hihost2
label var role1 "Role of 1 in dyadic dispute"
label def role12 1 "Primary initiator"
label val role1 role12
label var role2 "Role of 2 in dyadic dispute"
label def role22 3 "Primary target"
label val role2 role22 
label var warint "War initiation"
label var midint "MID initiation"
label var fmidint "Fatal MID initation"


* Save datatset
***************
order ddyadid, after(dyindex)
order midint, before(outcome)
sort year ccode1 ccode2
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\d-Militarized Interstate Disputes\scss-0101d-mid.dta", replace


* Close log *
*************
log close
exit

