* Open log *
************
capture log close
log using "Data Analysis\Replication Files\Stata Log Files\01-Data Management\01-Status Deficit & MID\a-Attributed Status\scss-0101a-attsts-b-ndeg" ,replace

*********************************************************************************
* Subset bonus weighted diplomatic exchange datatset into nodes and edges lists *
*********************************************************************************

* Programme: scss-0101a-attsts-b-ndeg.do
* Project: How States Really Respond to Status Dissatisfaction: a closer look at the material and temporal dynamics of status-driven conflict.
* Author: Matthew Tibbles

* Description *
***************
* This do-file subsets the bonus weighted diplomatic exchnage dataset by year and generates nodes and edge lists of each subset.
* The nodes and edges lists are exported to csv format in preparation for network analysis in Gephi.

* Set up Stata environment *
****************************
version 17
macro drop _all 
capture log close 
clear all 
drop _all 
set linesize 255

* Generate yearly subsets of the bonus weighted diplomatic exchange dataset 
*****************************************************************************
// Load diplomatic exchange bonus weighted dataset
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\a-Diplomatic Exchange Bonus Weighted\scss-0101a-attsts-a-dipxbw.dta" ,clear

// Drop redundant variables 
keep ccode1 ccode2 year dipxbw

// Preserve in memory
preserve

// Run the following commands for each year 
foreach x of numlist 1940 1950 (5) 2005 {
	
    *| Subset dataset by year of observation
    keep if year == `x' 

    *| Save subset
    compress
    save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\a-Diplomatic Exchange Bonus Weighted\scss-0101a-attsts-a-dipxbw-`x'.dta" ,replace
    restore, preserve
}


* Create nodes list from yearly subsets
********************************************************************************************************************************
// Load monadic State System Membership dataset 
import delimited "Status Conflict among Small States\Data Analysis\Datasets\Source\COW System Membership v.2016\system2016.csv", clear

// Drop redundant observations/variables
drop if year < 1940 | year > 2005
drop version 

// Identify and drop countries included multiple times in same year (under pre-unification code and under post-unification code)
*| Germany (255)
count if year >= 1990 & (ccode == 260 | ccode == 265)
tab year stateabb if year >= 1990 & (ccode == 260 | ccode == 265)
*|| 1 record for both GDR and GFR in year of German unification
drop if year == 1990 & (ccode == 260 | ccode == 265)
*|| Keep only post-unification codes for Germany in 1990

*| Yemen
count if year >= 1990 & (ccode == 678 | ccode == 680)
tab year stateabb if year >= 1990 & (ccode == 678 | ccode == 680)
*|| 1 record for YPR in year of Yemeni unification
drop if year >= 1990 & (ccode == 678 | ccode == 680)
*|| Keep only post-unification code for Yemen in 1990

*| Czech Republic (316)
count if year >= 1993 & ccode == 315
*|| No record of Czech Republic country code after 1992

*| Syria (652)
count if year >= 1958 & year < 1961 & ccode == 652
tab year if year >= 1958 & year < 1961 & ccode == 652
*|| 1 record for Syria in 1958
drop if year == 1958 & ccode == 652
*|| Syria entered into union with Egypt in 1958, so drop Syria 

// Rename variable 
rename stateabb cabb

// Label variables
label var ccode "COW country code"
label var cabb "COW country abbreviation"
label var year "Year"

// Save as stata dataset
order cabb, after(ccode)
sort year ccode
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-symemmon.dta" ,replace


// Run the following commands for each diplomatic exchange subset
foreach year of numlist 1940 1950 (5) 2005 {

    *| Load subset
    use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\a-Diplomatic Exchange Bonus Weighted\scss-0101a-attsts-a-dipxbw-`year'.dta" ,clear

    *| Drop second country code and tie information
    drop ccode2 dipxbw

    *| Keep only first occurence of each country 
    duplicates drop ccode1, force

    *| Merge with system membership data to obtain node labels i.e country abbreviations
    rename ccode1 ccode
    merge 1:1 ccode year using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-symemmon.dta", keep(match master) nogen 

    // Gephi format
    rename ccode id
    rename cabb label
    drop year
		
    *| Export nodes list to csv 
    export delimited  "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\b-Nodes and Edges\scss-0101a-attsts-b-nd-`year'.csv", replace
}


* Creates edges lists from yearly subsets
******************************************
// Run the following commands for each diplomatic exchange subset
foreach year of numlist 1940 1950 (5) 2005 {

    *| Load subset
    use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\a-Diplomatic Exchange Bonus Weighted\scss-0101a-attsts-a-dipxbw-`year'.dta" ,clear

    *| Reformat as Gephi edges list
    gen type ="Directed"
    rename ccode1 source 
    rename ccode2 target
    rename dipxbw weight
    order type, after(target)
    drop year
		
    *| Keep live ties only#
    drop if weight == 0    
		
    *| Export edges list to csv 
        export delimited "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\b-Nodes and Edges\scss-0101a-attsts-b-eg-`year'.csv" ,replace
}


* Close log *
*************
log close
exit












