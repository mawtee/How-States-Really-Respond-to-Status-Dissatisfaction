* Open log *
************

capture log close
log using "Data Analysis\Replication Files\Stata Log Files\01-Data Management\01-Status Deficit & MID\b-Expected Status\scss-0101b-expsts-a-pw" ,replace

*Programme: scss-0101b-expsts-a-pw.do
* Project: How States Really Respond to Status Dissatisfaction: a closer look at the material and temporal dynamics of status-driven conflict.
*Author: Matthew Tibbles

***************************************************
* Generate power-based expected status measures   *
***************************************************

* Description *
***************
* This do file generates community, regional and global measures expected status based on field-ranked CINC scores.

* Set up Stata environment *
****************************
version 17
macro drop _all 
capture log close 
clear all 
drop _all 
set linesize 255

* Generate expected status variables 
************************************
// Load data
use "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\02-Controls & Components\x-Embedded\scss-0102x-emb-mcap.dta" ,clear

// Drop redundant observations
drop if year < 1949 
drop if year > 2000

// Merge with attributed status dataset to obtain community and regional memberships
merge 1:1 ccode year using "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\e-Attributed Status Measures\scss-0101a-attsts-e-attstsm.dta" ,keep(match master) keepusing(com reg) nogen

// Re-order variables
order com reg, before(mcap)

// Generate expected community status
bysort year com: egen expcomstspw = rank(mcap), field

// Generate expected regional status
bysort year reg: egen expregstspw = rank(mcap), field

// Generate expected global status
bysort year: egen expgblstspw = rank(mcap), field

* Save dataset
*****************
// Label variables
label var expcomstspw "Expected communtity status (power)"
label var expregstspw "Expected regional status (power)"
label var expgblstspw "Expected global status (power)"

// Save
order com reg, before(mcap)
rename ccode ccode1
sort year ccode1
compress
save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\b-Expected Status\scss-0101b-expsts-a-pw.dta",replace


* Close Log *
*************
log close
exit




