* Open log *
************
capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\01-Status Deficit & MID\a-Attributed Status\scss-0101a-attsts-c-netstat2", replace

* Programme: scss-0101a-attsts-c-netstat2.do
* Project: Status Conflict among Small States
* Author: Matthew Tibbles


* Read in all Gephi csv files and save as stata datasets
********************************************************
*~ Run the following commands for each network statistics file
foreach year of numlist 1899 (5) 1914 1920 (5) 1940 1950 {
    
    /// Load csv
        import delimited "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\c-Network Statistics\scss-0101a-attsts-c-netstat-`year'.csv" ,clear


    /// Restore data to original format
        gen year = `year'
        order year, after(label)
        drop timeset
        rename id ccode
        rename label cabb
        rename pageranks pagerank
        rename cluster com
        sort ccode

    /// Label variables
        label var ccode "COW country code"
        label var cabb "COW country abbreviation"
        label var year "Year"
        label var pagerank "PageRank (0.85 damping factor and weighted edges)"
        label var com "Leiden community (modularity, 1.0 resolution and weighted edges)"
         
	///	Save as stata dataset
		compress
        save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\c-Network Statistics\scss-0101a-attsts-c-netstat-`year'.dta" ,replace
}

* Close Log *
*************
log close
exit









