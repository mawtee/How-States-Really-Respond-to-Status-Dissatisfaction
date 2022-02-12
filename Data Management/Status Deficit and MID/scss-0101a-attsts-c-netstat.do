* Open log *
************
capture log close
log using "Data Analysis\Replication Files\Stata Log Files\01-Data Management\01-Status Deficit & MID\a-Attributed Status\scss-0101a-attsts-c-netstat", replace

* Programme: scss-0101a-attsts-c-netstat.do
* Project: How States Really Respond to Status Dissatisfaction: a closer look at the material and temporal dynamics of status-driven conflict.
* Author: Matthew Tibbles

*****************************************************************
* Calculate PageRanks and detect Leiden communities using Gephi *
*****************************************************************

* Description *
***************
* This do-file provides exact instruction for the calulation of PageRank scores and the detection of Leiden communities using the open-source network analysis software Gephi.
* Gephi is used because implementation of PageRank -a theoretically informed baseline for the measurement of attributed status- is not a feature of any of the various
* network analysis packages currently available in Stata.
* Gephi results tables are subsequently exported to csv, and saved as Stata datasets.

* Set up Stata environment *
****************************
version 17
macro drop _all 
capture log close 
clear all 
drop _all 
set linesize 255

* Generate Gephi network and calculate network statistics for year of observation (using 1970 as example)
***********************************************************************************************************

*| Import nodes and edges into Gephi (1970 example)
*--------------------------------------------------
// Create new project in Gephi > Navigate to File > Import spreadsheet > scss-dtam01attstatus-b-nd-1970.csv > Import as Nodes table > Importeded columns: Id Label > Graph Type: Directed > Auto-scale: Yes > Self-loops: No: > Create missing nodes: No > Append to existing workspace 

// Navigate to the File Tab > Import spreadsheet > scss-dtam01attstatus-b-eg-1970.csv > Import as Edges table > Imported columns: Type, Weight > Edge Type: Double > Edge merge strategy: Don't merge > Self-loops: No > Append to existing workspace
*| Number of nodes: 134
*| Number of Edges: 4945 (exluding non-ties)

*| Calculate PageRank scores and detect Leiden communities (1970 example)
*------------------------------------------------------------------------
// Navigate to Statistics > Network Overview > PageRank > Run > Directed > Damping factor (p): 0.85 > Epsilon: 0.001 > Use edge weight: Yes > Ok
*| PageRank highest-lowest scores: 0.027527 USA - 0.001127 MAD

// Navigate to Statistics > Network Overview > Leiden algorithm > Run > Quality function: Modularity > Use edge weights: Yes>  Resolution: 0.975 > Number of iterations: 10 > Number of restarts: 5 > Random seed: 1 > Ok > Q: 0.15
*| Lieden community distribution: 0 (31.34%) 1 (29.1%) 2 (25.33%) 3 (13.43%) 4 (0.75% = no in-links)

*| Export network statistics to csv file
*-------------------------------------
/// Navigate to Data Laboratory > Export Table > scss-dtam01attstatus-c-netstat-1965.csv > Save


* Read in all Gephi csv files and save as Stata datasets
********************************************************
// Run the following commands for each network statistics file
foreach year of numlist 1940 1950 (5) 2005 {
    
    *| Load csv
    import delimited "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\c-Network Statistics\scss-0101a-attsts-c-netstat-`year'.csv" ,clear

    *| Restore data to original format
    gen year = `year'
    order year, after(label)
    drop timeset
    rename id ccode
    rename label cabb
    rename pageranks pagerank
    rename cluster com
    sort ccode

    *| Label variables
    label var ccode "COW country code"
    label var cabb "COW country abbreviation"
    label var year "Year"
    label var pagerank "PageRank (0.85 damping factor and weighted edges)"
    label var com "Leiden community (modularity, 1.0 resolution and weighted edges)"
         
    *| Save as Stata dataset
    compress
    save "Status Conflict among Small States\Data Analysis\Datasets\Derived\01-Data Management\01-Status Deficit & MID\a-Attributed Status\c-Network Statistics\scss-0101a-attsts-c-netstat-`year'.dta" ,replace
}


* Close Log *
*************
log close
exit










*Create graphical vizualisation of network (Figure 1)
*****************************************************
*Render node size by PageRank score (higher scores render larger sized nodes)
*-----------------------------------------------------------------------------
*Navigate to appearance > Nodes > Ranking > Size > PageRank > Min Size: 300 > Max Size: 1000 > Apply

*Partition nodes by Leiden communities
*----------------------------------------------
*Navigate to appearance > Nodes > Partition > Cluster > Default Palette > Apply

*Remove noisy single-member community (4 = ZIM)
*--------------------
*Navigate to Data Laboratory > Filter > Cluster > Descending Order > Delete ZIM  (OR NOT)

*View network using Fruchterman Reingold layout
*----------------------------------------------
*Navigate to layout > Fruchterman Reingold > Area: 1000000.0 > Gravity: 0.25 > Speed 1000.0 > Run

*Adjust overlapping labels
*--------------------------------
*Navigate to Label adjust > Speed: 1 > Include node size: Yes

*Manage preview settings and export as png
*-----------------------------------------
*Navigate to Preview > Presets > Default > Node labels > Show node labels: Yes > Font: Ariel Nova Cond 15 Bold > Proportional Size: Yes > Background: Hex 2B2B2B > Refresh 
*Navigate to Export > PNG file > Save as ""C:\Users\matti\Google Drive\Papers\1- Status Conflict among Small States\Data\Graphics\01-gephinetwork-2000.png"





*Load gephi export csv files and save as stata datasets
*******************************************************

*Run the following commands for each network statistics file
foreach year of numlist 1940 1950 (5) 2005 {

*Load csv file
import delimited "C:\Users\matti\Google Drive\Papers\1- Status Conflict among Small States\Data\Datasets\Derived\01-Data Management\01-Status Deficit\Attributed Status\c-Network Statistics\scss-dtam01attstatus-c-netstat-`year'.csv" ,clear

*Revert data to original format
rename id ccode
rename label cabb
rename pageranks pagerank
rename cluster com
drop timeset
sort ccode

*save as stata dataset
label var ccode "COW Country Code"
label var cabb "COW Country Abbreviation"
label var pagerank "PageRank (0.85 damping factor and weighted edges)"
save "C:\Users\matti\Google Drive\Papers\1- Status Conflict among Small States\Data\Datasets\Derived\01-Data Management\01-Status Deficit\Attributed Status\c-Network Statistics\scss-dtam01attstatus-c-netstat-`year'.dta" ,replace
}



