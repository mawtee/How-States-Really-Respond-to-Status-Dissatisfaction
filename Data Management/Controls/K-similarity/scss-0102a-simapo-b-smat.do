* Open log *
**********

capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\02-Controls & Components\a-Similarity\Alliance Portfolio\scss-0102a-simapo-b-smat" ,replace

**********************************************
* Generate alliance portfolio socio-matrices *
**********************************************

* Programme: scss-0102a-simapo-b-smat.do
* Project: Status Conflict among Small States
* Author: Matthew Tibbles
* Reference note: This programme is a modified transposition of the programme "msim-data03-allydyad.do" - authored by Frank Haege and accessed at 

* Description *
***************
* This code transforms the directed dyadic system membership-alliance type dataset ("scss-02simaport-a2-symematype.dta") into a square socio-matrix by reshaping the data from long to wide format.
* It generates a socio-matrix for the full time period and individual matrices for each year.


* Set up Stata *
****************
version 16
clear all
macro drop all


* Generate socio-matrix for entire time period                                      
***********************************************
/// Load self-referencing alliance type dataset
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\Alliance Portfolio\a-Self-Referencing Directed Dyadic\scss-0102a-simapo-a-srddyad.dta" ,clear

/// Reshape the data into a square socio-matrix*
drop ddyadid ccode2
reshape wide atype, i(year cabb1) j(cabb2) string
order year cabb1 ccode1 

/// Rename variables
rename cabb1 cabb
rename ccode1 ccode

/// Delete 'atype' from variable names and labels
unab vars : atype*
local a : subinstr local vars "atype" "", all
foreach y of local a {
	label var atype`y' `y'
}
foreach y of local a {
	rename atype`y' `y'
}
/// Save 
sort year cabb
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\Alliance Portfolio\b-Socio-Matrices\scss-0102a-simapo-b-smat" ,replace


* Generate an alliance type socio-matrix for each year
******************************************************
/// Load self-referencing alliance type dataset
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\Alliance Portfolio\a-Self-Referencing Directed Dyadic\scss-0102a-simapo-a-srddyad.dta"  ,clear

*~ Run the following commands for each year
foreach x of numlist 1949/2000 {
	
    /// Keep the full dataset in memory while transforming the data for individual years
        preserve

    /// Reshape the data for the respective into a square socio-matrix
        keep if year == `x'
        drop ddyadid ccode2
        reshape wide atype, i(year cabb1) j(cabb2) string

    /// Order and rename variables
        order year cabb1 ccode1 
        rename cabb1 cabb
        rename ccode1 ccode

    /// Delete 'atype' from variable names and labels
        unab vars : atype*
        local a : subinstr local vars "atype" "", all
        foreach y of local a {
	         label var atype`y' `y'
}
      foreach y of local a {
	         rename atype`y' `y'
}

    /// Save alliance portfolio socio-matrix for the respective year
        sort year cabb
        compress
        save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\Alliance Portfolio\b-Socio-Matrices\scss-0102a-simapo-b-smat-`x'.dta" ,replace
        
		restore
} 


* Close Log *
*************
log close
exit



