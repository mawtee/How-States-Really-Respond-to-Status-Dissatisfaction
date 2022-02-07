* Open log *
************
capture log close
log using "Status Conflict among Small States\Data Analysis\Replication Files\Stata Log Files\01-Data Management\02-Controls & Components\f-Temporal Dependence\scss-0102f-tempdep", replace

******************************************************
* Generate temporal dependence peace years variables *
******************************************************

* Programme: scss-0102f-tempdep.do
* Project: Status Conflict among Small States
* Author: Matthew Tibbles

* Description *
***************
* This do-file generates cubic polynomials and cubic splines of the COW peace years variable.
* The resulting variables are used to control and acount for the effects of the length of peace duration on the relatationship status deficit and the probablity of conflcit initation.

* Set up Stata *
****************
version 16
clear all
macro drop all
set linesize 90

* Generate dyadic peace years dataset
****************************************

/// Load peace years data
import delimited "C:\Users\matti\Documents\Papers\Status Conflict among Small States\Data Analysis\Datasets\Source\eugenepeaceyears.csv", clear 

/// Drop redundant observations/variables
keep ccode1 ccode2 year cwpceyrs
drop if year < 1949 | year > 2000

/// Save as temporary file
tempfile temptd
save "`temptd'"

/// Load dyadic system membership dataset
use "C:\Users\matti\Documents\Papers\Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-symemddyadsr.dta", clear 
 
/// Drop self-referencing dyads
drop if ccode1 == ccode2

/// Merge with peace years data
merge 1:1 ccode1 ccode2 year using "`temptd'", keep(match master) nogen

/// Rename peace years
rename cwpceyrs pceyrs


* Generate cubic polynomials/splines of peace years
****************************************************
/// Generate cubic polynomials
gen pceyrs2 = pceyrs^2
gen pceyrs3 = pceyrs^3


/// Generate naturual cubic smoothing splines
mkspline pceyrsspl = pceyrs, cubic knot(1,8, 17, 29,50) displayknots

* Save dataset
****************

/// Label variables
label var pceyrs "Peace years"
label var pceyrs2 "Peace years squared"
label var pceyrs3 "Peace years cubed"
label var pceyrsspl1 "Peace years spline 1"
label var pceyrsspl2 "Peace years spline 2"
label var pceyrsspl3 "Peace years spline 3"
label var pceyrsspl4 "Peace years spline 4"

/// Save 
sort ccode1 ccode2 year
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\f-Temporal Dependence\scss-0102f-tempdep.dta", replace


* Close log *
*************
 log close
 exit






* temporal dependence answers question of how the association between x and y varies over time - so all models needs to include x, using signorino's code to show how srength of coefficient of status deficit on mid varies over time via line graph, and also just taking strength of coefficient when time variables are included in model (build from signorino's code)
* so can simply include cubic polynomials and cubic splines in model, probably finding average coefficinet of cubic vars using lincom , at least for polynomials
* but can also plot temporal effects of peace years on status deficit as predictor of MID initiation (plots probability of status deficit on conflcit initation (y) at different peace year intervals (x)
* basicallhy want the reject the null hypothesis that the log odds of MID initation is a linear function of the length of peace duration, or at least that status deficit is stilll significnant when the length of peace duration is controlled for (and then a graph of this will show the relationship at different knot intervals - hopefully show that mid initation is no less liekly to occur when states have been at peace for 20 years vs 1 year, but after 25 years there is a linear trend)
* but basic model just looks at strength of status deficit, and controls, when (multiple)cubic polynomials and (multiple) cubic splines are included in the model, in other words, the strength of status deficit versus time - hopefully status deficit is be strong predictor of mid int, rather than mid initation being a linear function of the length of peace duration and status deficit coefficients being a linear function of peace duration (they, intuitively, are not)
* logit midint basis*
* low prob > chi2 = rejection of null hypothesis, i.e. no linear relationship between log odds and time
* xbrcspline for plot maybe.... could go in online appendix of pr at different knot levels,, showing non-linear curve of status def on mid init in terms of peace years duration(see also signorino code)

/// Generate cubic polynomials
gen cwpceyrs2 = cwpceyrs^2
gen cwpceyrs3 = cwpceyrs^3
merge 1:1 ccode1 ccode2 year using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\c-Militarized Interstate Disputes\scss-0101c-mid.dta", keepusing(midint fatmid)
replace midint = 0 if midint != 1
replace fatmid = 0 if fatmid != 1
spbase cwpceyrs, knots(1, 10, 25, 50, 100) gen(spline)
sort year ccode1 ccode2