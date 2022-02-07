* Open log *
************

capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\02-Controls & Components\a-Similarity\Total Bilateral Trade\scss-0102a-simtbitr-a-srdyad" ,replace

*********************************************************************************
* Generate a directed dyadic self-referencing dataset for total bilateral trade *
*********************************************************************************

* Programme: scss-0102a-simtbitr-a-srdyad.do
* Project: Status Conflict among Small States
* Author: Matthew Tibbles
* Reference note: This programme is a modified transposition of the programme "msim-data01-sysdyad.do" - authored by Frank Haege and accessed at 

* Description *
***************
* This do-file generates a directed dyadic self-referencing dataset of total bilateral trade figures between 1949 aqnd 2000.
* Using the dyadic version of the COW Trade Dataset v.4, it generates a dyadic total of bilateral trade flows ranked on annual deciles, and merges this with the directed dyadic self-referencing system membership dataset
* The resulting dataset is then cleaned in preparation for its transformation into a square socio-matrix.


* Set up Stata *
****************
version 16
clear all
macro drop all


* Load COW Trade v.4 dyadic dataset, generate total bilateral trade variables and save as stata dataset
************************************************************************************************

/// Load COW Trade v.4 dyadic dataset
 import delimited "Status Conflict among Small States\Data Analysis\Datasets\Source\COW_Trade_4.0\COW_Trade_4.0\Dyadic_COW_4.0.csv", clear 
 
/// Drop redundant observations
drop if year < 1949 | year > 2000

/// Drop redundant variables
keep ccode1 ccode2 year flow1 flow2 

/// Recode missing values 
count if (flow1 == -9 | flow2 == -9)
*| 138,819
*| Missing trade values are not reliable indicators of zero dyadic trade
*| This is chiefly because the the availability of trade figures is often entirely dependent on whether the respective states choose (or are able) to report trade flows to the IMF and other international financial institutions
*| This is best understood in contrast to missing values in the alliance, IGO and UN voting datasets, for which information is generally a matter of public record, or is at least recorded by, and thus accessible from, sources other than the states in question
*| One popular reponse to the problem of missing trade values is to recode all missing trade values as 0 or the mean vale. However, this arbitrarily distorts the spread of trade values towards 0/the mean - an issue exacerbated by the sheer number of missing trade values in the dataset
*| Hence, the optimal response is to recode missing trade values as missing values for the calculation of trade similarity measures, and then multiplicatively impute missing trade similarity values in the pre-processing stage, so as to eliminate the sample bias iccured by listwise deletion (during regression analysis) of cases with missing values
replace flow1 = . if flow1 == -9
replace flow2 = . if flow2 == -9

/// Generate total bilateral trade variable
gen tbitr = flow1 + flow2

/// Generate annual decile ranks of total bilateral trade (there is no need to generate real terms (constant) trade figures since both ranks and similarity measures are calculated on an annual (independent) basis)
bysort year: astile tbitrad = tbitr, nq(10)

// Identify and recode countries included multiple times in same year (under pre-unification code and under post-unification code)
* Germany (255)
count if year >= 1990 & (ccode1 == 260 | ccode1 == 265) | year >= 1990 & (ccode2 == 260 | ccode2 == 265)
*| 327
tab year ccode1 if year >= 1990 & (ccode1 == 260 | ccode1 == 265) 
*| 118 and 117 records on ccode1 for GDR and GFR respectively in year of German unification
tab year ccode2 if year >= 1990 & (ccode2 == 260 | ccode2 == 265)
*| 46 and 57 records on ccode1 for GDR and GFR respectively in year of German unification 
replace ccode1 = 255 if year >= 1990 & (ccode1 == 260 | ccode1 == 265)
replace ccode2 = 255 if year >= 1990 & (ccode2 == 260 | ccode2 == 265)
*| Recode GFR and GDR in year of German unification as 255 on ccode1 and ccode2

* Yemen (279)
count if year >= 1990 & (ccode1 == 678 | ccode1 == 680) | year >= 1990 & (ccode2 == 678 | ccode2 == 680)
*| 327
tab year ccode1 if year >= 1990 & (ccode1 == 678 | ccode1 == 680) 
*| 38 and 36 records on ccode1 for YAR and YPR respectively in year of Yemeni unification
tab year ccode2 if year >= 1990 & (ccode2 == 678 | ccode2 == 680) 
*| 126 and 128 records on ccode2 for YAR and YPR respectively in year of Yemeni unification
replace ccode1 = 679 if year >= 1990 & (ccode1 == 678 | ccode1 == 680)
replace ccode2 = 679 if year >= 1990 & (ccode2 == 678 | ccode2 == 680)
*| Recode YAR and YPR in year of German unification as 255 on ccode1 and ccode2

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
replace ccode1 = 651 if year >= 1958 & year < 1961 & ccode1 == 652 
replace ccode2 = 651 if year >= 1958 & year < 1961 & ccode2 == 652
*| Recode Syria as Egypt on during year of unification with Egypt

/// Drop self-referencing dyads on recoded countries
drop if ccode1 == ccode2 

/// Generate undirected dyad ID 
gen udyadid = min(ccode1 , ccode2)*1000 + max(ccode1 , ccode2)
order udyadid

/// Recode duplicated ties for countries inlcuded multiple times in same year as highest total bilateral trade decile rank for each directed dyad-year 
*| Tag duplicate observations for each dyad year
duplicates tag udyadid year, gen(dup)
*| Identify highest decile rank for each yearly dyad
bysort udyadid year: egen flag = max(tbitrad)
*| For each group of dyad-year duplicates, keep only the highest decile rank
drop if dup > 0 & tbitrad != flag
*| Drop all but first record of equally ranked duplicates
duplicates drop udyadid year, force
isid udyadid year
*| Dyad-year uniquely identifies the observations

/// Drop redundant variables
drop dup flag

/// Label variables
label var udyadid "Undirected dyad ID"
label var ccode1 "COW country code 1"
label var ccode2 "COW country code 2"
label var year "Year"
label var flow1 "Imports of country 1 from Country 2, in US millions of current dollars"
label var flow2 "Imports of country 2 from Country 1, in US millions of current dollars"
label var tbitr "Total bilateral trade"
label var tbitrad "Annual decile ranks of total bilateral trade"

/// Save as stata dataset
sort year ccode1 ccode2
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-tbitrudyad.dta", replace


* Merge state system membership dataset with total bilateral trade totals and prepare new datatset for transformation into socio-matrix
*****************************************************************************************************************************

/// Load directed dyadic self-referencing system membership dataset
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-symemddyadsr.dta" ,clear

/// Merge with bilateral trade dataset
merge m:1 udyadid year using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-tbitrudyad.dta", keepusing(tbitrad)

/// Review merge
tab _m
*| 1 = 7214 dyad-years for which there is no record in the trade dataset
*| 3 = remaining 1,060,142 dyads are recorded in both datasets

/// Troubleshoot and drop unmatched non-self-referencing dyads
gen self = 1 if ccode1 == ccode2 & ccode1 != .
count if self == 1
*| 7210 of 7214 unmatched records are self-referencing dyads
tab cabb1 cabb2 if _m == 1 & self != 1
*| All four master-only non-self-referencing dyads involve BNG in 1971 - leave trade values for all 4 dyads as missing

/// Recode total bilateral trade for self-referencing dyads as maximum trade that the respective state does with other states in the respective year
bysort ccode1 year: egen selftbitrad = max(tbitrad) 
replace tbitrad = selftbitrad if self == 1
note tbitrad: Self-referencing dyads represent the most trade that the respective state does with other states in the respective year i.e. its highest annual decile rank

/// Recode remaining missing and 1st decile valued self-referencing dyads as next-lowest self-referencing value in the respective year
gen flag2 = 1 if self == 1 & tbitrad == . | self == 1 & tbitrad == 1
replace tbitrad = 88 if flag2 == 1
bysort year: egen selftbitradmin = min(tbitrad) if self == 1
replace tbitrad = selftbitradmin if flag2 == 1

/// Drop redundant variables
drop udyadid _m self flag selftbitrad selftbitradmin flag2

/// Save
sort year ccode1 ccode2 
compress 
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\Total Bilateral Trade\a-Self-Referencing Directed Dyadic\scss-0102a-simtbitr-a-srddyad.dta", replace


* Close log *
*************
log close
exit


*****************************

/// Load CPI
import delimited "C:\Users\mattiDocuments\Papers\Status Conflict among Small States\Data Analysis\Datasets\Source\cpi_usbls.csv", clear

/// Drop redundant observations  
drop if year < 1949 | year > 2000


/// Rename variables
rename series_id components

/// Label variables

save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-acpi.dta", replace


*Merge with cpi_usbls and calculate 2000 terms trade figures (little research on cpi again, year 83 significance?, and also trade dependence var calculation, does it use total or flow1, and cpi application, 1hrmax, but not needed if just doing annual ranks anyway, only useful as embedded data, so still useful and still makes sense to do, and to rank on 2000 terms.
***********************************************************

/// Load total bilateral trade dataset
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-tbitradeudyad.dta", clear

/// Merge with cpi
merge m:1 year using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-acpi.dta", keepusing(acpi83) nogen

/// Calcute 2000 terms (more so for later calculation of global dependence)


save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-tbitradeudyad.dta", replace

/// Annual ranks

/// Annual decile ranks



*Load system membership and merge with trade2000 on country1 and country2 (rest is straight forward and QUICK, but go over all uses of symemon and chnage file name)
************************************************ 





*

*Load CPI, save as stata set, reload tbitrade, merge with cpi on year, calculate 2000 terms , save again. Tne load system membership data and merge with tibitrade, then save as self-referencing udyadid, done





