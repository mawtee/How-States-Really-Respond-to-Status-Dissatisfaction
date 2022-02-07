* Open log *
************

capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\02-Controls & Components\a-Similarity\IGO Joint Membership\scss-0102a-simigo-a-srddyad" ,replace

*******************************************************************************
* Generate a directed dyadic self-referencing dataset of IGO joint memberships*
*******************************************************************************

* Programme: scss-0102a-simigo-a-srddyad.do
* Project: Status Conflict among Small States
* Author: Matthew Tibbles
* Reference note: This programme is a modified transposition of the programme "msim-data01-sysdyad.do" - authored by Frank Haege and accessed at 

* Description *
***************
* This do-file generates a directed dyadic self-referencing dataset of IGO joint memberships between 1949 and 2000.
* Using the dyadic version of the International Governmental Organizations Dataset v.3, it generates a dyadic sum of joint IGO memberships ranked on annual deciles, and merges this with the directed dyadic self-referencing system membership dataset.
* The resulting dataset is then cleaned in preparation for its transformation into a square socio-matrix.


* Set up Stata *
****************

version 16
clear all
macro drop all


* Load IGO v.3 dyadic dataset, generate joint IGO memberships variables and save as stata dataset
************************************************************************************************

/// Load IGO v.3 dyadic dataset
 use "Status Conflict among Small States\Data Analysis\Datasets\Source\Intergovernmental Organisations v.3\IGO_dyadic_format3.dta", clear

/// Drop redundant observations
drop if year < 1949 | year > 2000

/// Recode missing (-9) and 'State not system member' (-1) values as 'No membership' (0)
foreach var of varlist aalco-omvg  {
    
    replace `var' = 0 if `var' == -9 | `var' == -1

}

/// Generate sum of joint igo memberships 
egen  igojms = rsum (aalco-omvg)

/// Identify and troubleshoot dyads with no common IGO memberships
count if igojms == 0
*| 5,863 dyads with no common memberships
gen flag = 1 if igojms == 0 
*| Calculate total no. observations for country1 in flagged dyads 
bysort flag ccode1: gen nobs = _N if flag == 1
tab nobs
*| Note that four countries are recorded two-three times more than others
tab country1 if (nobs == 204 | nobs == 239 | nobs == 258 | nobs == 306)
*| GDR 
*| MON
*| PRK
*| ZIM
*| At different points between 1949 and 2000, all four countries have experienced considerable political upheaveal and\or been isolated from the broader international community
*| In this context, it is not difficult to imagine that these few countries were (almost entirely) removed from IGO activity
*| Accordingly, dyads with no common IGO memberships are taken at face value, and so left untouched

/// Generate annual decile ranks of joint IGO memberships sum (by reducing the value scale of the variable, annual decile ranks promote  xxxxxx)
bysort year : astile igojmsad = igojms ,nq(10)

/// Identify and recode countries included multiple times in same year (under pre-unification code and under post-unification code)
* Germany (255)
count if year >= 1990 & (ccode1 == 260 | ccode1 == 265) | year >= 1990 & (ccode2 == 260 | ccode2 == 265)
*| No record of German pre-unification codes after 1989

* Yemen (279)
count if year >= 1990 & (ccode1 == 678 | ccode1 == 680) | year >= 1990 & (ccode2 == 678 | ccode2 == 680)
*| 0
*| No record of Yemeni pre-unification codes after 1989

* Czech Republic (316)
count if year >= 1993 & ccode1 == 315 | year >= 1993 & ccode2 == 315
*| No record of Czech Republic country code after 1992

*Syria (652)
count if year >= 1958 & year < 1961 & ccode1 == 652 | year >= 1958 & year < 1961 & ccode2 == 652
*| 89
tab year if year >= 1958 & year < 1961 & ccode1 == 652
*| 27 records on ccode1 for Syria in 1958 
tab year if year >= 1958 & year < 1961 & ccode2 == 652
*| 62 records on ccode2 for Syria in 1958
replace ccode1 = 651 if year >= 1958 & year < 1961 & ccode1 == 652 & ccode1 != 651
replace ccode2 = 651 if year >= 1958 & year < 1961 & ccode2 == 652
*| Recode Syria as Egypt on in year of unification with Egypt

/// Drop self-referencing dyads on recoded countries
drop if ccode1 == ccode2

/// Generate undirected dyadid ID
gen udyadid = min(ccode1 , ccode2)*1000 + max(ccode1 , ccode2)
order udyadid

/// Identify and drop duplicate observations
*| Tag duplicate observations for each dyad year
duplicates tag udyadid year, gen(dup)
*| Identify highest igo joint membership rank for each yearly dyad
bysort udyadid year: egen flag2 = max(igojmsad)
*| For each group of dyad-year duplicates, keep only the highest decile rank
drop if dup > 0 & igojmsad != flag2
*| Drop all but first record of equally weighted duplicates
duplicates drop udyadid year, force
isid udyadid year
*| Dyad-year uniquely identifies the observations

/// Drop redundant variables
keep ccode1 country1 ccode2 country2 year igojms igojmsad udyadid 

/// Sort dataset
sort year ccode1 ccode2

/// Rename variables
rename country1 cabb1 
rename country2 cabb2

/// Label variables
label var udyadid "Undirected dyad ID"
label var ccode1 "COW country code 1"
label var cabb1 "COW country abbreviation 1"
label var ccode2 "COW country code 2"
label var cabb2 "COW country abbreviation 2"
label var year "Year"
label var igojms "Sum of joint IGO memberships"
label var igojmsad "Annual decile rank on joint IGO memberships sum"

/// Save as stata dataset
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-igojmsudyad.dta" ,replace


* Merge system membership dataset with IGO joint memberships and prepare new datatset for transformation into socio-matrix
*****************************************************************************************************************************

/// Load directed dyadic self-referencing system membership dataset
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-symemddyadsr.dta" ,clear

/// Merge with IGO joint memberships
merge m:1 udyadid year using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-igojmsudyad.dta"

/// Review merge
tab _m
*| 1 = 7,210 dyad-years for which there is no record in the igo dataset 
*| 3 = remaining 1,060,146 dyad-years are recorded in both datasets
count if ccode1 == ccode2
*| 7,210 self-referencing dyads - no unmatched non-self-referencing dyads

/// Recode self-referencing dyads as max for country 1
gen self = 1 if ccode1 == ccode2
bysort ccode1 year: egen selfigojmsad = max(igojmsad) 
bysort ccode1 year: replace igojmsad = selfigojmsad if self == 1
note igojmsad: Self-referencing dyads represent the most IGO joint memberships that the respective state has with other states in the respective year i.e. its highest annual decile rank

/// Recode remaining missing and 1st decile valued self-referencing dyads as next-lowest self-referencing value in the respective year
gen flag3 = 1 if self == 1 & igojmsad == . | self == 1 & igojmsad == 1
replace igojmsad = 88 if flag3 == 1
bysort year: egen selfigojmsadmin = min(igojmsad) if self == 1
replace igojmsad = selfigojmsadmin if flag3 == 1

/// Drop redundant variables
drop igojms udyadid _m flag self selfigojmsad flag3 selfigojmsadmin

/// Save 
sort year ccode1 ccode2
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\IGO Joint Membership\a-Self-Referencing Directed Dyadic\scss-0102a-simigo-a-srddyad.dta" ,replace
     

* Close Log *
*************
log close
exit
