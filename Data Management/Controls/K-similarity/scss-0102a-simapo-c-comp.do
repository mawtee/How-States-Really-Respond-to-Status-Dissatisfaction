* Open log *
************

capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\02-Controls & Components\a-Similarity\Alliance Portfolio\scss-0102a-simapo-c-comp",replace

* Programme: scss-0102a-simapo-c-comp.do
* Project: Status Conflict among Small States
* Author: Matthew Tibbles
* Reference note: This programme is a modified transposition of the programme "msim-data07-allysimvalued.do" - authored by Frank Haege and accessed at 

***************************************************************************************************************
* Generate yearly datasets with component variables for calculation of alliance portfolio similarity measures *
***************************************************************************************************************

* Description *
***************
* This do-file generates the component variables for the calculation of three similarity measures - S-unweighted, Cohen's Kappa-unweighted and Scott's Pi-unweighted - based on alliance portfolio data.
* In the process, the yearly socio-matrices of alliance type ties are transformed into directed dyadic datatsets.


* Set up Stata *
****************
version 16
clear all
macro drop _all



* Generate a dataset for the respective year
********************************************

*~  Run the following commands for each year
foreach year of numlist 1949/2000 {
	
     /// Load directed dyadic alliance dataset of the respective year
         use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\Alliance Portfolio\b-Socio-Matrices\scss-0102a-simapo-b-smat-`year'.dta"  ,clear

     /// Generate temporary filename
	     tempname sim
	
	 /// Define variables and generate dataset
	     postfile `sim' /*
		 */ year nobs tnobs str3 cabb1 str3 cabb2 s1 s2 /*
		 */ ss1 ss2 m1 m2 var1 var2 /*
		 */ ssdmv1 ssdmv2 spdmv ssdmv ssd /*
		 */ mt ssdmt1 ssdmt2 spdmt /*
		 */ using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\Alliance Portfolio\c-Similarity Components\scss-0102a-simapo-c-comp-`year'.dta" ,replace

		 
   	 *   Loop through all country pairs in the respective year
	 *********************************************************
	
   	 /// Generate country abbreviation list for loop through country variables
	     unab varlist : _all
	     local cabblist : subinstr local varlist "year cabb ccode " ""
	
	 *~  Loop through all possible combinations of country pairs
	     foreach country1 of local cabblist {
		
		 foreach country2 of local cabblist {
			
			
			  *   Generate component variables for calculation of similarity
			  **********************************************************
			
			  /// Generate year variable
			      local year =`year'
			
			  /// Generate possible total number of observations
			       qui describe
			       local tnobs = r(N)
			
			  /// Generate country abbreviation variables
			      local cabb1 `country1'
			      local cabb2 `country2'
						
			  /// Generate non-missing value indicator
			      generate nonmiss =0
			      replace nonmiss = 1 if `cabb1'!=. & `cabb2'!=.
						
			  /// Generate number of non-missing observations
			      qui sum nonmiss
			      local nobs = r(sum)
			
			  /// Generate sum of variable values: sum(X) where X is the non-missing weighted alliance obligation that i has to k where, and only where, there is a non-missing record for the weighted alliance obligation that j has to k
		          qui sum `cabb1' if nonmiss ==1
			      local s1 = r(sum)
			      qui sum `cabb2' if nonmiss ==1
			      local s2 = r(sum)
			
			  /// Generate sum of squared values of variables: sum(X^2)
			      generate ss1 =`cabb1'^2 if nonmiss ==1
			      qui sum ss1
			      local ss1 = r(sum)
			      generate ss2 =`cabb2'^2 if nonmiss ==1
			      qui sum ss2
			      local ss2 =r(sum)
			
			  /// Generate mean of variable values: [sum(X)]/N
			      local m1 =`s1'/`nobs'
			      local m2 =`s2'/`nobs'
			
			  /// Generate sum of squared differences: sum[(X-Y)^2]
			      generate ssd =(`cabb1'-`cabb2')^2 if nonmiss ==1
			      qui sum ssd
			      local ssd =r(sum)
			
			  /// Generate variances: sum[(X-Y)^2]/N
			      generate var1 =(`cabb1'-`m1')^2 if nonmiss ==1
			      qui sum var1
			      local var1 =r(sum)/`nobs'
			      generate var2 =(`cabb2'-`m2')^2 if nonmiss ==1
			      qui sum var2
			      local var2 =r(sum)/`nobs'
			
			  *   Generate additional component variables for the calculation of Cohen's Kappa
			  *******************************************************************************
			
			  /// Generate sum of squared deviations from the variable mean: sum[(X-Xmean)^2]
			      generate ssdmv1 =(`cabb1'-`m1')^2 if nonmiss ==1
			      qui sum ssdmv1
			      local ssdmv1 =r(sum)
			      generate ssdmv2 =(`cabb2'-`m2')^2 if nonmiss ==1
			      qui sum ssdmv2
			      local ssdmv2 =r(sum)
			
			  /// Generate sum of products of deviations from the variable means: sum[(X-Xmean)*(Y-Ymean)]
			      generate spdmv =(`cabb1'-`m1')*(`cabb2'-`m2') if nonmiss ==1
			      qui sum spdmv
			      local spdmv =r(sum)
			
			  /// Generate sum of squared differences in variable means: sum[(Xmean-Ymean)^2]
			      local ssdmv =`nobs' * (`m1'-`m2')^2
			
			  *   Generate additional component variables for the calculation of Scott's Pi
			  *************************************************************************
			
			   /// Generate total mean: sum[(X+Y)]/(2*N)
			       generate mt = `cabb1'+`cabb2' if nonmiss == 1
			       qui sum mt
			       local mt = r(sum)/(2*`nobs')
			
			   /// Generate sum of squared deviations from the total mean: sum[(X-Mean)^2]
			       generate ssdmt1 = (`cabb1'-`mt')^2 if nonmiss == 1
			       qui sum ssdmt1
			       local ssdmt1 = r(sum)
			       generate ssdmt2 = (`cabb2'-`mt')^2 if nonmiss == 1
			       qui sum ssdmt2
			       local ssdmt2 = r(sum)
			
			   /// Generate sum of products of deviations from the total mean: sum[(X-Mean)*(Y-Mean)]
			       generate spdmt = (`cabb1'-`mt')*(`cabb2'-`mt') if nonmiss == 1
			       qui sum spdmt
			       local spdmt = r(sum)
			
			
		       *   Save newly generated variables to file
			    ***************************************
			
			    /// Post new variable values into a row of the dataset
			        post `sim' (`year') (`nobs') (`tnobs') ("`cabb1'") ("`cabb2'") (`s1') (`s2') /*
				    */  (`ss1') (`ss2') (`m1') (`m2') (`var1') (`var2') /*
			        */  (`ssdmv1') (`ssdmv2') (`spdmv') (`ssdmv') (`ssd') /*
				    */  (`mt') (`ssdmt1') (`ssdmt2') (`spdmt') 
		
	            /// Drop auxiliary variables
			        drop nonmiss-spdmt
	
		}
	
	 }

     /// Close dataset
	     postclose `sim'
	
		
	 *   Save dataset
	 ***************
     /// Load dataset   
			use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\Alliance Portfolio\c-Similarity Components\\scss-0102a-simapo-c-comp-`year'.dta" ,clear

	 /// Label variables
		 label var year "Year"
	     label var nobs "No. non-missing observations"
	     label var tnobs "Total no. observations"
	     label var cabb1 "COW country abbreviation 1"
         label var cabb2 "COW country abbreviation 2"
	     label var s1 "Sum Var1"
         label var s2 "Sum Var2"
	     label var ss1 "Sum squares Var1"
	     label var ss2 "Sum squares Var2"
	     label var m1 "Mean Var1"
	     label var m2 "Mean Var2"
	     label var var1 "Variance Var1"
	     label var var2 "Variance Var2"
	     label var ssdmv1 "SSD from var mean Var1"
	     label var ssdmv2 "SSD from var mean Var2"
	     label var spdmv "SPD from var means"
	     label var ssdmv "SSD of var means"
	     label var ssd "SSD"
	     label var mt "Total mean"
	     label var ssdmt1 "SSD from total mean Var1"
         label var ssdmt2 "SSD from total mean Var2"
         label var spdmt "SPD from total mean" 
        
	 /// Re-order variables	
		 order cabb1 cabb2, after(year)
		
	 /// Save
	     compress
	     save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\a-Similarity\Alliance Portfolio\c-Similarity Components\scss-0102a-simapo-c-comp-`year'.dta" ,replace

}


* Close Log *
*************
log close
exit

		
		
		
		
			




