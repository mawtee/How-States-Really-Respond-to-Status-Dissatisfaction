* Open log *
************
capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\01-Status Deficit & MID\a-Attributed Status\scss-0101a-attsts-b-ndeg2" ,replace

* Programme: scss-0101a-attsts-b-ndeg.do
* Project: Status Conflict among Small States
* Author: Matthew Tibbles

*********************************************************************************
* Subset bonus weighted diplomatic exchange datatset into nodes and edges lists *
*********************************************************************************

* Description *
***************
* This do-file subsets the bonus weighted diplomatic exchnage dataset by year and generates nodes and edge lists of each subset.
* The nodes and edges lists are exported to csv format in preparation for network analysis in Gephi.


* Set up Stata *
****************
version 16
clear all
macro drop all


* Generate subsets of the bonus weighted diplomatic exchange dataset for each year of observation (10 year interval for 1940 - and five year intervals from 1950 -2005)
**********************************************************************************************************************************************************************
/// Load diplomatic exchange bonus weighted dataset
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\a-Diplomatic Exchange Bonus Weighted\scss-0101a-attsts-a-dipxbw2.dta" ,clear

/// Drop redundant variables 
keep ccode1 ccode2 year dipxbw

/// Preserve in memory
preserve

*~ Run the following commands for each year 
foreach x of numlist 1899 (5) 1914 1920 (5) 1935 {
	
    /// Subset dataset by year of observation
        keep if year == `x' 

    /// Save subset
        compress
	    save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\a-Diplomatic Exchange Bonus Weighted\scss-0101a-attsts-a-dipxbw-`x'.dta" ,replace
        restore, preserve
}


* Generate a labeled nodes list of each subset of the diplomatic exchange bonus weighted dataset using system membership dataset
********************************************************************************************************************************
/// Load monadic state system membership dataset 
import delimited "Status Conflict among Small States\Data Analysis\Datasets\Source\COW System Membership v.2016\system2016.csv", clear

/// Drop redundant observations and version variables
drop if year < 1899 | year >1950
drop version 

/// Rename variable 
rename stateabb cabb

/// Label variables
label var ccode "COW country code"
label var cabb "COW country abbreviation"
label var year "Year"

/// Save as stata dataset
order cabb, after(ccode)
sort year ccode
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-symemmon2.dta" ,replace


*~ Run the following commands for each diplomatic exchange subset
foreach year of numlist 1899 (5) 1914 1920 (5) 1935 {

    /// Load subset
        use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\a-Diplomatic Exchange Bonus Weighted\scss-0101a-attsts-a-dipxbw-`year'.dta" ,clear

    /// Drop second country code and tie information
        drop ccode2 dipxbw

    /// Keep only first occurence of each country 
        duplicates drop ccode1, force

    /// Merge with system membership data to obtain node labels i.e country abbreviations
        rename ccode1 ccode
        merge 1:1 ccode year using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-symemmon2.dta", keep(match master) nogen 

    /// Reformat data as Gephi node list
        rename ccode id
        rename cabb label
		drop year
		
    /// Export nodes list to csv file
        export delimited  "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\b-Nodes and Edges\scss-0101a-attsts-b-nd-`year'.csv", replace
}


* Generate an edges list of each subset of the diplomatic exchange bonus weighted dataset
****************************************************************************************
*~ Run the following commands for each diplomatic exchange subset
foreach year of numlist 1899 (5) 1914 1920 (5) 1935 {

    /// Load subset
        use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\a-Diplomatic Exchange Bonus Weighted\scss-0101a-attsts-a-dipxbw-`year'.dta" ,clear

    /// Reformat data as Gephi edges list
        gen type ="Directed"
        rename ccode1 source 
        rename ccode2 target
        rename dipxbw weight
        order type, after(target)
		drop year
		
	/// Keep live ties only
		drop if weight == 0    
		
    /// Export edges list to csv file
        export delimited "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\b-Nodes and Edges\scss-0101a-attsts-b-eg-`year'.csv" ,replace
}


* Close log *
*************
log close
exit
