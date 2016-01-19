//  program:    VL2011_12.do
//  task:		Produce VL for 2011 and 2012
//  project:	Misc
//  author:     AV / Created: 15Aug2015 

***********************************************************************************************************
**************************************** Prep Data ********************************************************
***********************************************************************************************************
** Get IIntIDs from Demograpy dataset
use "$source/Demography/DemographyYear", clear

** Get relevant IDs and vars
keep IIntID  
duplicates drop IIntID, force
rename IIntID ACDIS_IIntID 

** Merge and only keep individuals linked to ACDIS
merge 1:m ACDIS_IIntID using "$source/ARTemis/LabResults", keep(match) nogen keepusing(TestDate LabTestCode RESULT Sex AgeTested) 
rename RESULT ViralLoad

** Keep specific years
gen TestYear = year(TestDate)
keep if inlist(TestYear, 2011, 2012)

** Keep only viral loads
keep if LabTestCode=="VL"

** Age
keep if inrange(AgeTested, 15, 65)
egen Age = cut(AgeTested), at(15(10)75) icode label

** Save datasets 
preserve
keep if TestYear==2011 
save "$derived/VL2011", replace
restore
preserve
keep if TestYear==2012 
save "$derived/VL2012", replace
restore


***********************************************************************************************************
**************************************** Prep Community VL ************************************************
***********************************************************************************************************
insheet using "$source\CommunityViralLoadWithARtemisData29jun2013.csv", clear

fdate date* , sfmt("YMD")

set seed 339487731
gen RandomUndetectable =int(1500*runiform()) if vlbelowldl == "Yes"
replace vlresultcopiesml=RandomUndetectable if  vlbelowldl=="Yes"









