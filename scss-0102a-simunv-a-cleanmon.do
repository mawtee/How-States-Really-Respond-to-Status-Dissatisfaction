*Open log 
**********

capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\02-Controls & Components\a-Similarity\UN Voting Record\scss-0102a-simunv-a-cleanmon", replace


****************************************************************************************
* Generate a clean version of the monadic UN voting dataset for all COW system members *
****************************************************************************************

* Programme:	scss-0102a-simunv-a-cleanmon.do
* Project:		Status Conflict among Small States
* Author:		Mastthew Tibbles

* Description
*************
* This do-file cleans data on voting in the UN General Assembly and merges it with the State System Membership dataset (msim-data01a-sysmemb.dta), 
* The latter is based on the system version of the COW State System Membership List (v2004.1).
* The resulting sample includes all COW state system members that were also UN members between 1946 and 2004.
* The input dataset for UN voting is the United Nations General Assembly Voting dataset collected by Voeten and Merdzanovic 
* (http://hdl.handle.net/1902.1/12379 UNF:3:Hpf6qOkDdzzvXF9m66yLTg== V1 [Version])


* Set up Stata
**************
version 16
clear all
macro drop _all
set linesize 80
set more off



* Prepare and generate additional voting dataset variables
**********************************************************

* Open the voting dataset
import delimited "Status Conflict among Small States\Data Analysis\Datasets\Source\UN Voting\unvotes.csv", clear
sort rcid date ccode

/// Drop redundant observations
drop if year < 1949 | year > 2000

* Rename and label variables
rename rcid rccode_orig
rename country cabb_un  
label var rccode_orig "Roll call code"
label var session "Session number"
label var unres "UNV Resolution code"
label var ccode "COW country code"
label var cabb_un "UNV country abbreviation"
label var year "Year"

* Generate voting date variable
rename date date_old
generate date = date(date_old, "YMD")
format date %td
label var date "Date"
drop date_old

* Generate month variable
generate month = month(date)
label var month "Month"

* Generate day variable
generate day = day(date)
label var day "Day"

* Generate type of vote variable
rename vote votetype
label var votetype "Type of vote"
label def votetypel 1 "Yes" 2 "Abstain" 3 "No" 8 "Absent" 9 "Non-member"
label val votetype votetypel

* Check type of vote variable
list rccode_orig-day if votetype == 11 | votetype == 5
* No undefined/missing values


* Correct country coding discrepancies between UN voting and COW system membership data
***************************************************************************************
/// Germany
* Check whether there are any observations incorrectly coded with the pre-1990 country code
sort year
by year: tab votetype if date >= td(3oct1990) & (ccode == 260 | ccode == 265) 
*| Country code is 260 after 3oct1990, but should be 255
tab year if date >= td(3oct1990) & ccode == 260
*| Country code is 265 after 3oct1990, but should be 255
tab year if date >= td(3oct1990) & ccode == 265
* Recode voting data country code as correct COW country code
replace ccode = 255 if date >= td(3oct1990) & (ccode == 260 | ccode == 265)

/// Yemen
* Check whether there are any observations incorrectly coded with the pre-1990 country code
sort year
by year: tab votetype if date >= td(22may1990) & (ccode == 678 | ccode == 680)
* Country code is 678 after 1990, but should be 679
tab year if date >= td(22may1990) & ccode == 678
*|  Country code is 680 after 1990, but should be 679
tab year if date >= td(22may1990) & ccode == 680
* Recode voting data country code to correct COW country code
replace ccode = 679 if date >= td(22may1990) & (ccode == 678 | ccode == 680)

/// Czech republic
* Check whether Czech republic received country code of Czechoslowakia after 1992
sort year
by year: tab votetype if date >= td(01jan1993) & ccode == 315
* Czechoslovakia does not exist after 1992 
tab year if date >= td(01jan1993) & ccode == 315
*| The vote variable shows only 'absent' (8) or 'non-member' (9) after 1992
*| Drop observations for Czechoslovakia after 1992
drop if date >= td(01jan1993) & ccode == 315

/// Syria was part of Egypt between 1958 and 1961
* Check whether Syria country code appears between 1958 and 1961
sort year
by year: tab votetype if date >= td(01feb1958) & date < td(29sep1961) & ccode == 652
*| Country code 652 appears between 1958 and 1961
tab year if date >= td(01feb1958) & date < td(29sep1961) & ccode == 652
* Check for records of Syria and Egypt voting for same resolution
sort unres ccode
list unres date ccode votetype if date >= td(01feb1958) & date < td(29sep1961) & (ccode == 651 | ccode == 652)
* There are various records of Syria and Egypt voting for same resolution in this time period
* Syria and Egypt could not have voted for same resolution, so drop observations for Syria
drop if date >= td(01feb1958) & date < td(29sep1961) & ccode == 652

/// Taiwan
* Taiwan is not recognized as independent country in COW data before 1949
* Check if Taiwan appears in voting data before 1949
sort year
by year: tab votetype if date < td(08dec1949) & ccode == 713
by year: tab votetype if date < td(08dec1949) & ccode == 710
* China is coded as 'non-member' for this period
* Drop China observations as non-members and recode Taiwan votes as China votes
tab year if date < td(08dec1949) & ccode == 710
drop if date < td(08dec1949) & ccode == 710
tab year if date < td(08dec1949) & ccode == 713
replace ccode = 710 if date < td(08dec1949) & ccode == 713
tab year if date < td(08dec1949) & ccode == 710
by year: tab votetype if date < td(08dec1949) & ccode == 710

/// China
* China takes over UN seat from Taiwan in 1971
sort year
by year: tab votetype if date >= td(25oct1971) & ccode == 713
by year: tab votetype if date >= td(25oct1971) & ccode == 710
* Taiwan observations incorrectly hold votes of China in 1972 and 1973
* Drop 'non-member' observations of China in 1972 and 1973
tab year if (year == 1972 | year == 1973) & ccode == 710
drop if (year == 1972 | year == 1973) & ccode == 710
* Recode Taiwan observations as China observations for 1972 and 1973
tab year if (year == 1972 | year == 1973) & ccode == 713
replace ccode = 710 if (year == 1972 | year == 1973) & ccode == 713
by year: tab votetype if date >= td(25oct1971) & ccode == 710

* Correct country codes for new UN members that have an incorrect COW country code in voting data
* Kiribati (946, 1999-)
replace ccode = 946 if ccode == 970
* Nauru (970, 1999-)
replace ccode = 970 if ccode == 946  & cabb_un == "NRU"

* Identify and drop duplicate observations
********************************************
*| Tag duplicate observations by country-year-rccode
duplicates tag ccode year rccode_orig, gen(dup)
*| Identify duplicates by ccode
tab ccode if dup != 0 
*| 255 (GMY) 
*| 345 (YUG)
*| 679 (YEM)
*| Duplicate observations on country code 345 caused by seperate records for "Yugoslavia" "Serbia and Montenegro" and "Serbia"
*| According to COW system membership coding, country code 345 refers exclusively to Yugoslavia up to and including 2005, so drop all observations on other two countries
drop if dup != 0 & countryname == "Serbia" 
drop if dup != 0 & countryname == "Serbia and Montenegro" 
*| Duplicate observations on Germany and Yemen are dropped on the basis of votetype value (see below)


* Merge the voting data with COW system membership data
*******************************************************
* Prepare system membership dataset for merge
preserve
	use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-symemmon.dta", clear
	sort year ccode
	save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-symemmon.dta", replace
restore

* Merge the datasets
sort year ccode
merge m:1 year ccode using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-symemmon.dta", keep(match)


* Check which observations were in system membership data but not in voting data
********************************************************************************
* Review merge
tab _merge
tab year if _merge == 2

* Drop observations with years earlier than 1949
drop if year < 1949
*| Sample used in this paper begins in 1950(lagged by 1 year)

* Drop observations in year 1964
drop if year == 1964
* There were no recorded votes during this year

* Drop observations for Vietnam (COW code 817, 1954-1975)
drop if ccode == 817
* No voting data for this country because it was not a member of the UN during that time period

* Drop those observations that resulted from some countries changing status during a year
list year votetype ccode cabb cabb_un if _merge == 2
* Taiwan is only recognized as a separate state by COW data in 1949 and was not member
* of the UN anymore in 1972 and 1973
drop if _merge == 2 & cabb == "TAW"

/// Check whether there are any remaining unmatched observations
count if _merge == 2
*| No unmatched observations remain

* Check which observations were in voting data but not in system membership data
********************************************************************************
* Review merge 
tab _merge, m
tab year if _merge == 1

* Drop cases that were definitely not UN members (according to both sources)
drop if votetype == 9 & _merge == 1

* Drop observations for Belarus and Ukraine before their independence in 1991
drop if cabb_un == "BLR" & year < 1991 & _merge == 1
drop if cabb_un == "UKR" & year < 1991 & _merge == 1

* Check whether there are any remaining unmatched observations
count if _merge == 1
*| No unmatched observations remain


* Further corrections, deletion of variables and observations, and generation of new variables
**********************************************************************************************
/// Drop redundant variables
drop dup cabb_un _merge

* Drop non-member state observations
tab votetype 
drop if votetype == 9
*| All duplicates resulting from recoding of Germany and Yemen are coded as 9 (non-member), and so are dropped 

* Generate running number as roll call vote identification variable
sort date rccode_orig
egen rccode = group(date rccode_orig)
label var rccode "Roll call code (running number)"

* Drop redundant variables
drop member countryname abstain-importantvote amend-resid

* Save dataset
order session rccode rccode_orig unres date day month year cabb ccode votetype 
sort rccode ccode
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\UN Voting Record\a-Cleaned Monadic\scss-0102a-simunv-a-cleanmon.dta", replace


* Close log *
*************
log close
exit