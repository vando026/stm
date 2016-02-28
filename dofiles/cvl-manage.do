//  program:    VL2011_12.do
//  task:		Produce VL for 2011 and 2012
//  project:	Misc
//  author:     AV / Created: 15Aug2015 

***********************************************************************************************************
**************************************** Prep Data ********************************************************
***********************************************************************************************************
** Get IIntIDs from Demograpy dataset 2014
use "$source/Demography/DemographyYear", clear

** Get relevant IDs and vars
duplicates drop IIntID, force
clonevar ACDIS_IIntID = IIntID 
keep IIntID ACDIS_IIntID Sex 
distinct IIntID 

tempfile Demo
sav "`Demo'"

***********************************************************************************************************
**************************************** Facility VL ******************************************************
***********************************************************************************************************
** Merge if only want to keep individuals linked to ACDIS
use "`Demo'", clear

merge 1:m ACDIS_IIntID using "$source/ARTemis/LabResults" , keep(match) nogen keepusing(TestDate LabTestCode RESULT AgeTested) 
distinct ACDIS_IIntID 

** Keep only viral loads
keep if LabTestCode=="VL"
rename RESULT ViralLoad
sum ViralLoad, d

** In 2011, VL or 1 or 40 is undetectable
if "$VLImpute"=="Yes" {
  set seed 339487734
  gen RandomUndetectable =ceil(1500*runiform()) if ViralLoad <=40
  replace ViralLoad = RandomUndetectable if ViralLoad<=40
} 

** Keep specific years
gen TestYear = year(TestDate)
keep if inlist(TestYear, 2011)

** Age
keep if inrange(AgeTested, 15, 65)
egen Age = cut(AgeTested), at(15, 20, 25, 35, 45, 55, 100) icode label

drop ACDIS_IIntID 
keep IIntID Sex TestDate TestYear ViralLoad Age

** Save datasets 
preserve
keep if TestYear==2011 
distinct IIntID 
save "$derived/FVL2011", replace
restore

***********************************************************************************************************
********************************************* Community VL ************************************************
***********************************************************************************************************
use "$source/Individuals/RD01-01 ACDIS Individuals", clear
keep IIntID DateOfBirth 
duplicates drop IIntID, force
tempfile Individuals
save "`Individuals'"

insheet using "$source/CommunityVL/CommunityViralLoadWithARtemisData29jun2013.csv", clear 
fdate datereceivedatacvl, sfmt("YMD")

rename iintid IIntID 
rename datereceivedatacvl TestDate
gen TestYear = year(TestDate)

** Get Sex and other  vars
merge m:1 IIntID using "`Demo'", keep(match) nogen keepusing(Sex)
merge m:1 IIntID using "`Individuals'", keep(match) nogen

gen AgeYr = int((TestDate - DateOfBirth)/365.25) 
egen Age = cut(AgeYr), at(15, 20, 25, 35, 45, 55, 100) icode label

set seed 339487731
gen RandomUndetectable =int(1500*runiform()) if vlbelowldl == "Yes"
replace vlresultcopiesml =RandomUndetectable if  vlbelowldl =="Yes"
rename vlresultcopiesml ViralLoad
drop if missing(ViralLoad)

keep IIntID Sex TestDate TestYear ViralLoad Age

save "$derived/CVL2011", replace

/*
use "$source/Demography/DemographyYear", clear
keep IIntID ObservationStart
keep if IIntID==13
bysort IIntID (ObservationStart): gen ObservationEnd = ObservationStart[_n+1] - 1
format ObservationEnd %td
