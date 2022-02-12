* Open log *
************
capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\01-Status Deficit & MID\a-Attributed Status\scss-0101a-attsts-a-dipxbw" ,replace

* Project: Status Conflict among Small States
* Programme: scss-0101a-attsts-a-dipxbw.do
* Author: Matthew Tibbles

**************************************************************************************************
* Generate weighted diplomatic exchange datatset adjusted for low-capability-high distance bonus *
**************************************************************************************************

* Description *
***************
* This do-file recodes the weighted diplomatic exchange dataset by applying a bonus treatment to relevant dyads.
* Where the capital-to-capital distance between a dyad pair is greater than the mean, and where the material capabilities of the sending state are below the median, 
* the level of diplomatic representation of country i at country j is mulitplied by 1.5 so as to give greater weight to the particuarly costly investment of sending
* embassies for states with geographical and material constraints.

* Set up Stata environment *
****************************
version 17
macro drop _all 
capture log close 
clear all 
drop _all 
set linesize 255

* Clean/recode directed dyadic Diplomatic Exchange dataset
************************************************************************************

// Import data
import delimited "Status Conflict among Small States\Data Analysis\Datasets\Source\Diplomatic Exchnage v2006.1\diplomatic_exchange_2006v1.csv" ,clear   

// Drop redundant observations/variables
drop if year < 1940 
drop version

// Keep only ties catologued by dr_at_2 (inlinks defined as 'Diplomatic representation level of side 1 at side 2')
drop dr_at_1       
drop de

// Reccode tie weights 
replace dr_at_2 =4 if dr_at_2 == 3
replace dr_at_2 =3 if dr_at_2 == 2
replace dr_at_2 =2 if dr_at_2 == 1

// Recode all level-9 ties (referring to either unceartain or less important levels of diplomatic representation) as 1
// These ties now represent the lowest weight for all years of observation excluding 1950, 1955, 1960 & 1965, where default coding for all ties during this period is 9 (now 1)
// due to issues around data avilability
replace dr_at_2 =1 if dr_at_2 == 9

// Tabulate by year to verify correct weighting of ties 
bysort year: tab dr_at_2

// Identify and recode countries included multiple times in same year (under pre-unification code and under post-unification code)
*| Germany (255)
count if year >= 1990 & (ccode1 == 260 | ccode1 == 265) 
tab year ccode1 if year >= 1990 & (ccode1 == 260 | ccode1 == 265)
replace ccode1 = 255 if year >= 1990 & (ccode1 == 260 | ccode1 == 265)
replace ccode2 = 255 if year >= 1990 & (ccode2 == 260 | ccode2 == 265)
*| Yemen (279)
count if year >= 1990 & (ccode1 == 678 | ccode1 == 680) 
tab year ccode1 if year >= 1990 & (ccode1 == 678 | ccode1 == 680)
replace ccode1 = 679 if year >= 1990 & (ccode1 == 678 | ccode1 == 680)
replace ccode2 = 679 if year >= 1990 & (ccode2 == 678 | ccode2 == 680)
*| Czech Republic (316)
count if year >= 1993 & ccode1 == 315
*|| No record for Czech Republic post 1993
*| Syria (652)
count if year >= 1958 & year < 1961 & ccode1 == 652
*|| No record for Syria between 1958 and 1960

// Drop self-referencing dyads on recoded countries
drop if ccode1 == ccode2

// Tag duplicate ties 
duplicates tag ccode1 ccode2 year, gen(dup)

// Identify highest weighted duplicates by dyad-year
bysort ccode1 ccode2 year: egen flag = max(dr_at_2)

// For each group of dyad-year duplicates, keep only the highest weight
drop if dup > 0 & dr_at_2 != flag

// Drop remaining duplicates
duplicates drop ccode1 ccode2 year, force
isid ccode1 ccode2 year

// Drop redundant variables
drop dup flag

// Rename and label variables
rename dr_at_2 dipxw
label var ccode1 "COW country code 1"
label var ccode2 "COW country code 2"
label var year "Year"
label var dipxw "Weighted diplomatic representation level of 1 at 2"

// Save as Stata dataset
sort year ccode1 ccode2
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\a-Diplomatic Exchange Bonus Weighted\scss-0101a-attsts-a-dipx.dta" ,replace


* Clean Minimum Country-to-Country Distance dataset
**********************************************************************
// Load data
import delimited "Status Conflict among Small States\Data Analysis\Datasets\Source\ccdistgled.2001.csv" ,clear

// Identify and drop duplicate observations 
bysort numa numb: gen nobs = _N
list if nobs > 1
*| Observations for both Serbia and Yugoslavia on same country code (345)
drop if ida == "SER"
drop if idb == "SER"
*| Drop observations for Serbia (not a recognised state before 2006)
isid numa numb

// Drop redundant variables 
drop ida idb nobs midist

// Rename variables
rename numa ccode1
rename numb ccode2
rename kmdist ccdist

/// Generate (undirected) dyad ID 
gen udyadid =min(ccode1, ccode2)*1000+max(ccode1,ccode2)
order udyadid 

// Label variables
label var udyadid "Undirected dyad id"
label var ccode1 "COW country code 1"
label var ccode2 "COW country code 2"
label var ccdist "Capital-to-capital distance"

// Save as Stata dataset
sort ccode1 ccode2
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-dist.dta" ,replace


* Clean National Material Capabilities country-year datatset 
**********************************************************************************************
// Load National Material Capabilities dataset
import delimited "Status Conflict among Small States\Data Analysis\Datasets\Source\National Material Capabilities v.2005\NMC_5_0.csv", clear

// Drop redundant observations/variables
drop if year < 1940 
drop if year > 2005
keep ccode year cinc

// Identify and drop countries included multiple times in same year (under pre-unification code and under post-unification code)
*| Germany (255)
count if year >= 1990 & (ccode == 260 | ccode == 265) 
tab year ccode if year >= 1990 & (ccode == 260 | ccode == 265)
*|| 1 record for both GDR and GFR in year of German unification
drop if year >= 1990 & (ccode == 260 | ccode == 265)
*|| Keep capabilities metric for Germany only 

* Yemen (279)
count if year >= 1990 & (ccode == 678 | ccode == 680) 
tab year ccode if year >= 1990 & (ccode == 678 | ccode == 680)
*|| 1 record for both YPR and YAR in year of Yemeni unification
drop if year >= 1990 & (ccode == 678 | ccode == 680)
*|| Keep capabilities metric for Yemen only

*| Czech Republic (316)
count if year >= 1993 & ccode == 315
*|| No record of Czech Republic country code after 1992

*| Syria (652)
count if year >= 1958 & year < 1961 & ccode == 652
tab year if year >= 1958 & year < 1961 & ccode == 652
*|| 1 record for Syria in 1958
drop if year == 1958 & ccode == 652
*|| Syria entered into union with Egypt in 1958, so drop Syria in 1958

// Rename and label variables
rename cinc mcap
label var ccode "COW country code"
label var year "Year"
label var mcap "Material capabilities"

// Save as stata dataset
sort year ccode
order ccode
compress
save  "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-mcap.dta"  ,replace


* Merge diplomatic exchnage dataset with distance and material capabilities data
*******************************************************************************
// Load diplomatic exchange dataset
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\a-Diplomatic Exchange Bonus Weighted\scss-0101a-attsts-a-dipx.dta" ,clear

// Merge with distance dataset
merge m:1 ccode1 ccode2 using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-dist.dta", keep(match master)

/// Review merge
tab _merge
*| master only(1): 1.13%
*| matched(3): 98.87%

// Identify unmatched 'live' ties'
list ccode1 ccode2 if _merge ==1 & dipxw > 0
count if _merge ==1 & dipxw > 0
*| 29 unmatched live ties
list ccode1 ccode2 if _merge ==1 & dipxw > 0
gen flag = 1 if _merge == 1 & dipxw > 0
bysort flag: count if ccode1 < 900 & ccode2 < 900
*| In 29 of 29 unmatched live ties side1 or side2 is country in pacific region of Asia
*| Coding errors on ceartain small pacific states are well documented in the literture, though this is due to discrepancies between COW and G&W country coding schemes
*| Accordingly, unmatched distance values are left as missing since both the diplomatic exchange and minimum distance datasets use the COW coding scheme

// Drop redundant variable
drop _merge flag

/// Merge with material capabilities dataset
rename ccode1 ccode
merge m:1 ccode year using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-mcap.dta", keep(match master) 

// Review merge
tab _merge
*|matched(3): 100.00%

// Drop redundant variable and sort
drop _merge
rename ccode ccode1
sort year ccode1 ccode2

* Calculate components for and apply bonus weights
***************************************************************************
// Generate median distance measure by year
by year: egen mddist = median(ccdist)

// Generate median material capabilities measure by year
by year: egen mdcap = median(mcap)

// Generate distance bonus indicator (distance > median)
gen distb = 1 if ccdist > mddist

// Generate capabilities bonus indicator (capabilities < mean
gen capb = 1 if mcap < mdcap

// Generate distance-capabilities bonus indicator 
gen distcapb = 1 if distb == 1 & capb == 1
replace distcapb = 0 if distcapb == .

// Generate diplomatic exchnage weights adjusted for distance-capabilities bonus
gen dipxbw = dipxw
replace dipxbw = dipxbw * 1.5 if distcapb == 1

// Calculate percenatge of live ties treated with bonus adjustment
count if inrange(dipxw, 1, 4)
local total = r(N)
count if distcapb == 1 & dipxw != 0
local bonus = r(N)
dis (`bonus' / `total') * 100
*|6.63% of live ties recieve bonus weight

// Tabulate bonus-adjusted weight scale
tab dipxbw
*|0 = No evidence
*|1 = Unclear
*|1.5 = Unclear with bonus weight
*|2 = Chargé d'affaires 
*|3 = Minister or chargé d'affaires with bonus adjustment
*|4 = Ambassador
*|4.5 = Minister with bonus weight
*|6 = Ambassador with bonus weight

// Label variables
label var mddist "Median capital-to-capital distance by year"
label var mdcap "Median material capabilities by year"
label var distb "Distance bonus indicator"
label var capb "Material capabilities bonus indicator"
label var distcapb "Distance-capabilities bonus indicator"
label var dipxbw "Diplopmatic representation level of 1 at 2 with bonus weight(1.5x if mcap<md & ccdist>md)"

// Save
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\a-Diplomatic Exchange Bonus Weighted\scss-0101a-attsts-a-dipxbw.dta" ,replace


* Close Log *
*************
log close 
exit













