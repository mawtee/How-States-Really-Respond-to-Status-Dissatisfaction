* Open log *
************
capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\02-Controls & Components\f-Temporal Dependence\scss-0102f-tempdep", replace

* Programme: scss-0102f-tempdep.do
* Project: Status Conflict among Small States
* Author: Matthew Tibbles

******************************************************
* Generate temporal dependence peace years variables *
******************************************************

* Description *
***************
* This do-file cleans and reshapes the monadic country-year COW peace years dataset and generates a peace years cubic splines with 4 knots.

* Set up Stata environment *
****************************
version 17
macro drop _all 
capture log close 
clear all 
drop _all 
set linesize 255

* Reshape peace years dataset from monadic to directed dyadic
*****************************************************************

// Load peace years data
import delimited "C:\Users\matti\Documents\Papers\Status Conflict among Small States\Data Analysis\Datasets\Source\eugenepeaceyears.csv", clear 

// Drop redundant observations/variables
keep ccode1 ccode2 year cwpceyrs
drop if year < 1949 | year > 2000

// Save as temporary file
tempfile temptd
save "`temptd'"

// Load dyadic system membership dataset
use "C:\Users\matti\Documents\Papers\Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-symemddyadsr.dta", clear 
 
// Drop self-referencing dyads
drop if ccode1 == ccode2

// Merge with peace years data
merge 1:1 ccode1 ccode2 year using "`temptd'", keep(match master) nogen

// Rename 
rename cwpceyrs pceyrs


* Generate cubic splines of peace years (and save)
****************************************************
// Generate naturual cubic smoothing splines
mkspline pceyrsspl = pceyrs, cubic knot(1,8, 17, 29,50) displayknots

// Label variables
label var pceyrs "Peace years"
label var pceyrs2 "Peace years squared"
label var pceyrs3 "Peace years cubed"
label var pceyrsspl1 "Peace years spline 1"
label var pceyrsspl2 "Peace years spline 2"
label var pceyrsspl3 "Peace years spline 3"
label var pceyrsspl4 "Peace years spline 4"

// Save 
sort ccode1 ccode2 year
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\f-Temporal Dependence\scss-0102f-tempdep.dta", replace


* Close log *
*************
 log close
 exit


