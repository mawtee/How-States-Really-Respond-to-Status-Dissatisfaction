* Open log *
************
capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\01-Status Deficit & MID\a-Attributed Status\scss-0101a-attsts-a-dipxbw" ,replace

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
drop if year < 1940 
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

/// Tabulate by year to verify correct weighting of ties 
bysort year: tab dr_at_2
*| 1950-1965
*---------
*| 0 = No evidence of diplomatic representation
*| 1 = Evidence of diplomatic representation
*------------------------------------------------
*| 1940/1970-2005
*--------------
*| 0 = No evidence of diplomatic representation
*| 1 = Diplomatic representation at unclear or low level
*| 2 = Diplomatic representation at level of chargé d'affaires 
*| 3 = Diplomatic repesentation at level of minister
*| 4 = Diplomatic representation at level of ambassador


/// Identify and recode countries included multiple times in same year (under pre-unification code and under post-unification code)
* Germany (255)
count if year >= 1990 & (ccode1 == 260 | ccode1 == 265) 
*| 326
tab year ccode1 if year >= 1990 & (ccode1 == 260 | ccode1 == 265)
*| 163 records on ccode1 for both GDR and GFR in year of German unification
replace ccode1 = 255 if year >= 1990 & (ccode1 == 260 | ccode1 == 265)
replace ccode2 = 255 if year >= 1990 & (ccode2 == 260 | ccode2 == 265)
*| Recode GDR and GFR in year of German unification as 255 on ccode1 and ccode2

* Yemen (279)
count if year >= 1990 & (ccode1 == 678 | ccode1 == 680) 
*| 326
tab year ccode1 if year >= 1990 & (ccode1 == 678 | ccode1 == 680)
*| 163 records on ccode1 for both YPR and YAR in year of Yemeni unification
replace ccode1 = 679 if year >= 1990 & (ccode1 == 678 | ccode1 == 680)
replace ccode2 = 679 if year >= 1990 & (ccode2 == 678 | ccode2 == 680)
*| Recode YPR and YAR in year of Yemeni unification as 279 on ccode1 and ccode2

* Czech Republic (316)
count if year >= 1993 & ccode1 == 315
*| No record for Czech Republic after 1992

*Syria (652)
count if year >= 1958 & year < 1961 & ccode1 == 652
*| No record for Syria between 1958 and 1960

/// Drop self-referencing dyads on recoded countries
drop if ccode1 == ccode2

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
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\a-Diplomatic Exchange Bonus Weighted\scss-0101a-attsts-a-dipx.dta" ,replace


* Load Minimum Distance v.2001 dyadic dataset and save as stata dataset
**********************************************************************
/// Load Minimum Distance dataset
import delimited "Status Conflict among Small States\Data Analysis\Datasets\Source\ccdistgled.2001.csv" ,clear

/// Identify and drop duplicate observations 
bysort numa numb: gen nobs = _N
list if nobs > 1
*| Observations for both Serbia and Yugoslavia on same country code (345)
drop if ida == "SER"
drop if idb == "SER"
*| Drop observations for Serbia (not a recognised state before 2006)
isid numa numb
*| Variables ccode1 and ccode2 unqiuely identify the observations


/// Drop redundant variables 
drop ida idb nobs midist

/// Rename variables
rename numa ccode1
rename numb ccode2
rename kmdist ccdist

/// Generate dyad ID 
gen udyadid =min(ccode1, ccode2)*1000+max(ccode1,ccode2)
order udyadid 

/// Label variables
label var udyadid "Undirected dyad id"
label var ccode1 "COW country code 1"
label var ccode2 "COW country code 2"
label var ccdist "Capital-to-capital distance"


/// Save as stata dataset
sort ccode1 ccode2
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-dist.dta" ,replace


* Load National Material Capabilities v.2000 country-year datatset and save as stata datatset 
**********************************************************************************************
/// Load National Material Capabilities dataset
import delimited "Status Conflict among Small States\Data Analysis\Datasets\Source\National Material Capabilities v.2005\NMC_5_0.csv", clear

/// Drop redundant observations and variables
drop if year < 1940 
drop if year > 2005
keep ccode year cinc

/// Identify and drop countries included multiple times in same year (under pre-unification code and under post-unification code)
* Germany (255)
count if year >= 1990 & (ccode == 260 | ccode == 265) 
*| 2
tab year ccode if year >= 1990 & (ccode == 260 | ccode == 265)
*| 1 record for both GDR and GFR in year of German unification
drop if year >= 1990 & (ccode == 260 | ccode == 265)
*| Keep capabilities metric for Germany only 

* Yemen (279)
count if year >= 1990 & (ccode == 678 | ccode == 680) 
*| 2
tab year ccode if year >= 1990 & (ccode == 678 | ccode == 680)
*| 1 record for both YPR and YAR in year of Yemeni unification
drop if year >= 1990 & (ccode == 678 | ccode == 680)
*| Keep capabilities metric for Yemen only

* Czech Republic (316)
count if year >= 1993 & ccode == 315
*| No record of Czech Republic country code after 1992

*Syria (652)
count if year >= 1958 & year < 1961 & ccode == 652
*| 1
tab year if year >= 1958 & year < 1961 & ccode == 652
*| 1 record for Syria in 1958
drop if year == 1958 & ccode == 652
*| Syria entered into union with Egypt in 1958, so drop Syria in 1958


/// Rename and label variables
rename cinc mcap
label var ccode "COW country code"
label var year "Year"
label var mcap "Material capabilities"


/// Save as stata dataset
sort year ccode
order ccode
compress
save  "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-mcap.dta"  ,replace


* Merge diplomatic exchnage dataset with distance and material capabilities data
*******************************************************************************
/// Load diplomatic exchange dataset
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\a-Diplomatic Exchange Bonus Weighted\scss-0101a-attsts-a-dipx.dta" ,clear

/// Merge with distance dataset
merge m:1 ccode1 ccode2 using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-dist.dta", keep(match master)

/// Review merge
tab _merge
*|master only(1): 1.13%
*|matched(3): 98.87%

/// Identify unmatched 'live' ties'
list ccode1 ccode2 if _merge ==1 & dipxw > 0
count if _merge ==1 & dipxw > 0
*| 29 unmatched live ties
list ccode1 ccode2 if _merge ==1 & dipxw > 0
gen flag = 1 if _merge == 1 & dipxw > 0
bysort flag: count if ccode1 < 900 & ccode2 < 900
*| In 29 of 29 unmatched live ties side1 or side2 is country in pacific region of Asia
*| Coding errors on ceartain small pacific states are well documented in the literture, though this is due to discrepancies between COW and G&W country coding schemes
*| Accordingly, unmatched distance values are left as missing since both the diplomatic exchange and minimum distance datasets use the COW coding scheme

/// Drop redundant variable
drop _merge flag

/// Merge with material capabilities dataset
rename ccode1 ccode
merge m:1 ccode year using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-mcap.dta", keep(match master) 

/// Review merge
tab _merge
*|matched(3): 100.00%

/// Drop redundant variable and sort
drop _merge
rename ccode ccode1
sort year ccode1 ccode2


* Calculate components for and apply lo-capability-hi-distance bonus weights
***************************************************************************

/// Save distribution statistics for distance to local macros  
sum ccdist, detail
local avdi = r(mean)
local sddi = r(sd)
local m1sddi = `avdi' -`sddi'
local m2sddi = `avdi' - `sddi'*2
local 1sddi = `avdi' + `sddi'
local 2sddi = `avdi' + `sddi'*2
local mddi = r(p50)
local skdi = r(skewness)
local ktdi = r(kurtosis)
local skdif : di %3.2f `skdi'
local ktdif : di %3.2f `ktdi'

/// Visualize distribution of distance variable
histogram ccdist, percent kdenop(gauss width(1500)) bin(20) xaxis(1 2) xlabel(`m2sddi' "-2 s.d." `m1sddi' "-1 s.d" `avdi' "Mean" `1sddi' "1 s.d" `2sddi' "2 s.d", axis(2) labsize(vsmall) grid gmax) xmtick(`mddi' , axis(2)) xtitle ("Distance - capital-to-captial", axis(1)) ytitle("% of Observations") title ("{bf} Moderately right skewed distribution (sk = `skdif', kt = `ktdif')") addplot(function 100 * 1500 * normalden(x, `avdi', `sddi'), range(`m2sddi' `2sddi' )) legend(on position(2) ring(0) rows(3) label (1 "% of Observations") label (2 "Observed distribution") label (3 "Normal distribution") size(vsmall)) text(15.15 `mddi' "Median", size(vsmall)) scheme(tibplotplain) saving("Status Conflict among Small States\Data Analysis\Graphics\scss-graph01-disthist.gph", replace) name(disthist, replace)
*| Variable exhibits a moderately right skewed distribution, and so the median is preferred to the mean as a measure of central tendency.

/// Display distribution statistics for material capabilities by year
sort year ccode1 ccode2
by year: sum mcap, detail

///Save distribution statistics for material capabilities variable to local macros  ************** FINISH THIS***********THEN RUN BOXTID ON MCAP, GET TO WORK ON KFP, THEN TRANSSFORM THOSE AS LOG AND OTHERS AS POWER TRANSFORMS. 
sum mcap if year == 2000, detail
local avmc = r(mean)
local sdmc = r(sd)
local m1sdmc = `avmc' -`sdmc'
local m2sdmc = `avmc' - `sdmc'*2
local 1sdmc = `avmc' + `sdmc'
local 2sdmc = `avmc' + `sdmc'*2
local mdmc = r(p50)
local skmc = r(skewness)
local ktmc = r(kurtosis)
local skmcf : di %3.2f `skmc'
local ktmcf : di %3.2f `ktmc'


/// Visualize 2000 distribution
histogram mcap if year == 2000, percent kdenop(gauss) width(.005) xaxis(1 2) xlabel(`m2sdmc' "-2 s.d" `m1sdmc' "-1 s.d" `avmc' "Mean" `1sdmc' "1 s.d" `2sdmc' "2 s.d", axis(2) labsize(vsmall) grid gmax) xmtick(`mdmc', axis(2)) xtitle ("Material capabilities", axis(1)) ytitle("% of Observations") title ("{bf}Leptokurtic distribution with severe right skew (sk = `skmcf', kt = `ktmcf')") note("{it} Data for the year 2000 only") addplot(function 100 * 0.005 * normalden(x, `avmc' , `sdmc'), range(`m2sdmc' `2sdmc')) legend(on position(2) ring(0) label (1 "% of Observations") label (2 "Observed distribution") label (3 "Normal distribution") size(vsmall)) text(225.75 `mdmc' "Median", size(vsmall)) scheme(tibplotplain) saving("Status Conflict among Small States\Data Analysis\Graphics\scss-graph02-mcaphist.gph", replace) name(mcaphist, replace)
*| Around 75% of observations fall below the mean and so the median provides a much more robust measure of central tendency.

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
*|70,022
count if distcapb == 1 & dipxw != 0
*|4,642
display (4642 / 70022) * 100
*|6.63% of live ties recieve bonus weight

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
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\a-Diplomatic Exchange Bonus Weighted\scss-0101a-attsts-a-dipxbw.dta" ,replace


* Close Log *
*************
log close 
exit













