* Open log *
************
capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\02-Controls & Components\a-Similarity\Alliance Portfolio\scss-0102a-simapo-a-srddyad" ,replace

**********************************************************************
* Generate a directed dyadic self-referencing alliance-type dataset *
**********************************************************************

* Programme: scss-0102a-simapo-a-atypesr.do
* Project: Status Conflict among Small States
* Author: Matthew Tibbles
* Reference note: This programme is a modified transposition of the programme "msim-data01-sysdyad.do" - authored by Frank Haege and accessed at 

* Description *
***************
* This do-file generates a directed dyadic self-referencing alliance type dataset for all states between 1949 and 2000.
* It cleans and recodes the directed dyadic COW State System Membership data v 2004.1 and the COW Formal Interstate Alliance dataset v4.1, and then merges the two datatsets together. 


* Set up Stata *
****************
version 16
clear all
macro drop all


* Generate directed dyadic self-referencing system membership dataset 
*****************************************************************************************
/// Load COW system membership monadic dataset
import delimited "Status Conflict among Small States\Data Analysis\Datasets\Source\COW System Membership v.2016\system2016.csv", clear 

/// Drop redundant observations and version variable
drop if year < 1949 | year > 2000
drop version

/// Rename variables
rename ccode ccode1
rename stateabb cabb1

/// Identify and drop countries included multiple times in same year (under pre-unification code and under post-unification code)
*Germany (255)
count if year >= 1990 & (ccode1 == 260 | ccode1 == 265)
*| 2
tab year cabb1 if year >= 1990 & (ccode1 == 260 | ccode1 == 265)
*| 1 record for both GDR and GFR in year of German unification
drop if year == 1990 & (ccode1 == 260 | ccode1 == 265)
*| Keep only post-unification codes for Germany in 1990

*Yemen
count if year >= 1990 & (ccode1 == 678 | ccode1 == 680)
*| 1
tab year cabb1 if year >= 1990 & (ccode1 == 678 | ccode1 == 680)
*| 1 record for YPR only in year of Yemeni unification
drop if year >= 1990 & (ccode == 678 | ccode == 680)
*| Keep only post-unification code for Yemen in 1990

* Czech Republic (316)
count if year >= 1993 & ccode1 == 315
*| No record of Czech Republic country code after 1992

*Syria (652)
count if year >= 1958 & year < 1961 & ccode == 652
*| 1
tab year if year >= 1958 & year < 1961 & ccode == 652
*| 1 record for Syria in 1958
drop if year == 1958 & ccode == 652
*| Syria entered into union with Egypt in 1958, so drop Syria 


/// Preserve dataset in memory'
preserve

/// Rename variables
 rename ccode1 ccode2
 rename cabb1 cabb2
 
/// Create and save temporary file
 tempfile copy
 save `copy'

/// Restore preserved dataset
 restore
 
/// Joint with temporary file
 joinby year using `copy'

/// Generate directed and undirected dyad idenitifiers
gen ddyadid = (ccode1*1000) + ccode2
gen udyadid = min(ccode1,ccode2)*1000 +max(ccode1,ccode2)
order ddyadid udyadid

/// Check that directed dyad-year uniquiely identify observations
isid ddyadid year

/// Label variables
label var ddyadid "Directed dyad ID"
label var udyadid "Undirected dyad ID"
label var ccode1 "COW country code 1"
label var cabb1 "COW country abbreviation 1"
label var ccode2 "COW country code 2"
label var cabb2 "COW country abbreviation 2"
label var year "Year"

/// Save 
order ddyadid udyadid ccode1 cabb1 ccode2 cabb2 year
sort ccode1 ccode2 year
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-symemddyadsr.dta", replace


* Load, recode and save directed dyadic COW Alliance dataset v4.1 as stata dataset
**********************************************************************************
/// Load dataset
import delimited "Status Conflict among Small States\Data Analysis\Datasets\Source\COW Alliances v4.1\alliance_v4.1_by_directed_yearly.csv", clear 

/// Drop redundant variables and observations
keep ccode1 ccode2 defense neutrality nonaggression entente year
drop if year < 1949 | year > 2000

/// Generate alliance type variable (1=entente; 2=neutrality/nonaggression; 3=defense) using highest weighted alliance for each yearly dyad
gen atype = 3 if defense == 1
replace atype = 2 if nonaggression == 1 & defense != 1 | neutrality == 1 & defense != 1
replace atype = 1 if entente == 1 & nonaggression != 1 & neutrality != 1 & defense != 1
*| Drop redundant variables
drop defense nonaggression neutrality entente 

/// Identify and drop countries included multiple times in same year (under pre-unification code and under post-unification code)
* Germany (255)
count if year >= 1990 & (ccode1 == 260 | ccode1 == 265) | year >= 1990 & (ccode2 == 260 | ccode2 == 265)
*| 226
tab year ccode1 if year >= 1990 & (ccode1 == 260 | ccode1 == 265)
*| 24 records on ccode1 for both GDR and GFR in year of German unification, as well as 8 records in 1991 and 9 records in every year between 1992 and 2000 
tab year ccode2 if year >= 1990 & (ccode2 == 260 | ccode2 == 265)
*| 24 records on ccode1 for both GDR and GFR in year of German unification, as well as 8 records in 1991 and 9 records in every year between 1992 and 2000 
replace ccode1 = 255 if year >= 1990 & (ccode1 == 260 | ccode1 == 265)
replace ccode2 = 255 if year >= 1990 & (ccode2 == 260 | ccode2 == 265)
*| Recode GDR and GFR in post-unification years as 255 on ccode1 and ccode2

*Yemen
count if year >= 1990 & (ccode1 == 678 | ccode1 == 680) | year >= 1990 & (ccode2 == 678 | ccode2 == 680)
*| 146
tab year ccode1 if year >= 1990 & (ccode1 == 678 | ccode1 == 680)
*| 36 and 39 records on ccode1 for YPR and YAR respectively in year of Yemeni unification
tab year ccode2 if year >= 1990 & (ccode2 == 678 | ccode2 == 680)
*| 36 and 39 records on ccode2 for YPR and YAR respectively in year of Yemeni unification
replace ccode1 = 679 if year >= 1990 & (ccode1 == 678 | ccode1 == 680)
replace ccode2 = 679 if year >= 1990 & (ccode2 == 678 | ccode2 == 680)
*| Recode YPR and YAR in year of Yemeni unification as 255

* Czech Republic (316)
count if year >= 1993 & ccode1 == 315 | year >= 1993 & ccode2 == 315
*| No record of Czech Republic country code after 1992

* Syria (652)
count if year >= 1958 & year < 1961 & ccode1 == 652 | year >= 1958 & year < 1961 & ccode2 == 652
*| 120
tab year if year >= 1958 & year < 1961 & ccode1 == 652
*| 20 records on ccode1 for Syria in 1958, 1959 and 1961 respectively
tab year if year >= 1958 & year < 1961 & ccode2 == 652
*| 20 records on ccode2 for Syria in 1958, 1959 and 1961 respectively
replace ccode1 = 651 if year >= 1958 & year < 1961 & ccode1 == 652
replace ccode2 = 651 if year >= 1958 & year < 1961 & ccode2 == 652
*| Recode Syria as Egypt on during year of unification with Egypt

/// Drop self-referencing dyads on recoded countries
drop if ccode1 == ccode2

/// Identify and drop duplicate observations
*| Tag duplicate observations for each dyad year
duplicates tag ccode1 ccode2 year, gen(dup)
*| Identify highest weighted alliance for each yearly dyad
bysort ccode1 ccode2 year: egen flag = max(atype)
*| For each group of dyad-year duplicates, keep only the highest valued alliance
drop if dup > 0 & atype != flag
*| Drop all but first record of equally weighted duplicates
duplicates drop ccode1 ccode2 year, force
isid ccode1 ccode2 year
*| Dyad-year uniquely identifies the observations

/// Generate directed dyad ID
gen ddyadid =(ccode1*1000) + ccode2
order ddyadid

/// Recode missing values as 0 (No alliance)
replace atype = 0 if atype == .

/// Drop redundant variables
drop dup flag 

/// Label variables
label var ddyadid "Directed Dyad ID"
label var year "Year"
label var ccode1 "COW country code 1"
label var ccode2 "COW country code 2"
label var atype "Alliance type"
label define atypev 0 "No alliance" 1 "Entente" 2 "Neutrality/nonaggression" 3 "Defence"
label value atype atypev

/// Save stata dataset
order ddyadid ccode1 ccode2 year
sort year ccode1 ccode2
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-atypeddyad.dta" ,replace


* Merge state system membership dataset with alliance dataset and prepare new datatset for transformation into socio-matrix
************************************************************************************************************************
/// Load self-referencing directed dyadic system membership dataset
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-symemddyadsr.dta" ,clear

/// Merge
merge 1:1 ddyadid year using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-atypeddyad.dta"

/// Review merge
tab _m
*|1 = dyad-year for which states are not in a formal alliance
*|2 = dyad-year for which at least one side is not formally recognised as a state system member
*|3 = dyad year for which states are in a formal alliance

/// Drop dydad-years where at least one side is not recognised as state system member
drop if _m == 2
drop _m

/// Recode self-referencing dyads as defensive pacts (3)
replace atype = 3 if ccode1 == ccode2
note atype: Self-referencing dyads are coded as defensive pacts 

/// Recode missing alliance type values as No alliance (0)
replace atype = 0 if atype == .

/// Drop redundant variable
drop udyadid

/// Re-order variables and sort
order ddyadid ccode1 cabb1 ccode2 cabb2 year atype
sort year ccode1 ccode2

/// Save
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\Alliance Portfolio\a-Self-Referencing Directed Dyadic\scss-0102a-simapo-a-atypesr.dta" ,replace


* Close log *
***********
log close
exit


