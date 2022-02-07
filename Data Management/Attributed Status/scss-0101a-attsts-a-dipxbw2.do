* Open log *
************
capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\01-Status Deficit & MID\a-Attributed Status\scss-0101a-attsts-a-dipxbw2" ,replace

* Programme: scss-0101a-attsts-a-dipxbw.do
* Project: Status Conflict among Small States
* Author: Matthew Tibbles

**************************************************************************************************
* Generate weighted diplomatic exchange datatset adjusted for low-capability-high distance bonus *
**************************************************************************************************

* Description *
***************
* This do-file recodes the weighted diplomatic exchange dataset by applying a bonus treatment to relevant dyads.
* Where the capital-to-capital distance between a dyad pair is greater than the mean, and where the material capabilities of the sending state are below the mean, the level of diplomatic representation of 1 at 2 is mulitplied by 1.5 so as to give greater weight to the particuarly costly investment of sending embassies under considerbale material and geographical constraints.


* Set up Stata *
****************
version 16
clear all
macro drop all


* Load directed dyadic Diplomatic Exchnage v2006.1 dataset and save as stata dataset
************************************************************************************
/// Import directed dyadic Diplomatic Exchange dataset
import delimited "Status Conflict among Small States\Data Analysis\Datasets\Source\Diplomatic Exchnage v2006.1\diplomatic_exchange_2006v1.csv" ,clear   

/// Drop redundant observations and version variable
drop if year < 1899 | year >= 1940
drop version

/// Keep only ties catologued by dr_at_2 (inlinks defined as 'Diplomatic representation level of side 1 at side 2')
drop dr_at_1       
drop de

/// Reccode tie weights 
replace dr_at_2 =4 if dr_at_2 == 3
replace dr_at_2 =3 if dr_at_2 == 2
replace dr_at_2 =2 if dr_at_2 == 1

/// Recode all level-9 ties (referring to a range of'other', either unceartain or less important levels of diplomatic representation) as 1, accordingingly coding these ties as the lowest weight for all years of observation excluding 1950, 1955, 1960 & 1965, where default coding for all ties during this period is 9 (here recoded as 0 1) due to issues around data avilability
replace dr_at_2 =1 if dr_at_2 == 9


/// Recode duplicated ties for countries inlcuded multiple times in same year as highest weighted diplomatic representation level for each directed dyad-year 
*| Tag duplicate observations for each dyad year
duplicates tag ccode1 ccode2 year, gen(dup)
*| Identify highest weighted diplomatic representation level for each dyad-year
bysort ccode1 ccode2 year: egen flag = max(dr_at_2)
*| For each group of dyad-year duplicates, keep only the highest weight
drop if dup > 0 & dr_at_2 != flag
*| Drop all but first record of equally weighted duplicates
duplicates drop ccode1 ccode2 year, force
isid ccode1 ccode2 year
*| Dyad-year uniquely identifies the observations

/// Drop redundant variables
drop dup flag

/// Rename and label variables
rename dr_at_2 dipxw
label var ccode1 "COW country code 1"
label var ccode2 "COW country code 2"
label var year "Year"
label var dipxw "Weighted diplomatic representation level of 1 at 2"

/// Save as stata dataset
sort year ccode1 ccode2
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\a-Diplomatic Exchange Bonus Weighted\scss-0101a-attsts-a-dipx2.dta" ,replace



* Load National Material Capabilities v.2000 country-year datatset and save as stata datatset 
**********************************************************************************************
/// Load National Material Capabilities dataset
import delimited "Status Conflict among Small States\Data Analysis\Datasets\Source\National Material Capabilities v.2005\NMC_5_0.csv", clear

/// Drop redundant observations and variables
drop if year < 1899
drop if year >= 1940
keep ccode year cinc

/// Rename and label variables
rename cinc mcap
label var ccode "COW country code"
label var year "Year"
label var mcap "Material capabilities"

/// Save as stata dataset
sort year ccode
order ccode
compress
save  "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-mcap2.dta"  ,replace



* Merge diplomatic exchnage dataset with distance and material capabilities data
*******************************************************************************
/// Load diplomatic exchange dataset
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\a-Diplomatic Exchange Bonus Weighted\scss-0101a-attsts-a-dipx2.dta" ,clear

/// Merge with distance dataset
merge m:1 ccode1 ccode2 using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-dist.dta", keep(match master)

/// Review merge
tab _merge
*|matched(3): 100%

/// Drop redundant variable
drop _merge

/// Merge with material capabilities dataset
rename ccode1 ccode
merge m:1 ccode year using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-mcap2.dta", keep(match master) 

/// Review merge
tab _merge
*|matched(3): 100.00%

/// Drop redundant variable and sort
drop _merge
rename ccode ccode1
sort year ccode1 ccode2


* Calculate components for and apply lo-capability-hi-distance bonus weights
***************************************************************************

/// Generate median distance measure by year
by year: egen mddist = median(ccdist)

/// Generate median material capabilities measure by year
by year: egen mdcap = median(mcap)

/// Generate distance bonus indicator
gen distb = 1 if ccdist > mddist

/// Generate capabilities bonus indicator
gen capb = 1 if mcap < mdcap

/// Generate distance-capabilities bonus indicator
gen distcapb = 1 if distb == 1 & capb == 1
replace distcapb = 0 if distcapb == .

/// Generate diplomatic exchnage weights adjusted for distance-capabilities bonus
gen dipxbw = dipxw
replace dipxbw = dipxbw * 1.5 if distcapb == 1

/// Calculate percenatge of live ties treated with bonus adjustment
count if inrange(dipxw, 1, 4)
*|7369
loca tties = r(N)

count if distcapb == 1 & dipxw != 0
*|861
local bties = r(N)

display (`bties' / `tties') * 100
*|11.6% of live ties recieve bonus weight

/// Tabulate bonus-adjusted weight scale
tab dipxbw
*|0 = No evidence
*|1 = Unclear
*|1.5 = Unclear with bonus weight
*|2 = Chargé d'affaires 
*|3 = Minister or chargé d'affaires with bonus adjustment
*|4 = Ambassador
*|4.5 = Minister with bonus weight
*|6 = Ambassador with bonus weight

/// Label variables
label var mddist "Median capital-to-capital distance by year"
label var mdcap "Median material capabilities by year"
label var distb "Distance bonus indicator"
label var capb "Material capabilities bonus indicator"
label var distcapb "Distance-capabilities bonus indicator"
label var dipxbw "Diplopmatic representation level of 1 at 2 with bonus weight(1.5x if mcap<md & ccdist>md)"

/// Save
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\a-Diplomatic Exchange Bonus Weighted\scss-0101a-attsts-a-dipxbw2.dta" ,replace


* Close Log *
*************
log close 
exit





