//  program:    VL2011_12.do
//  task:		Produce VL for 2011 and 2012
//  project:	Misc
//  author:     AV / Created: 15Aug2015 

***********************************************************************************************************
**************************************** Prep Data ********************************************************
***********************************************************************************************************
** Get IIntIDs from Demograpy dataset 2014
use "$AC_Data/Demography/2015/RD02-002_Demography", clear

** Get relevant IDs and vars
duplicates drop IIntID, force
clonevar ACDIS_IIntID = IIntID 
keep IIntID ACDIS_IIntID Sex 
distinct IIntID 

tempfile Demo
sav "`Demo'"

use "$AC_Source/ARTemis/ARTemisAll2013A", clear 
rename IIntId IIntID
keep IIntID Sex DateOfInitiation
drop if missing(DateOfInitiation)
format DateOfInitiation %td
rename Sex Sex_Artemis
duplicates list IIntID
tempfile ARTDate
save "`ARTDate'" 


***********************************************************************************************************
**************************************** Facility VL ******************************************************
***********************************************************************************************************
** Merge if only want to keep individuals linked to ACDIS
use "`Demo'", clear

merge 1:m ACDIS_IIntID using "$AC_Source/ARTemis/LabResults" , keep(match) nogen keepusing(TestDate LabTestCode RESULT AgeTested) 
merge m:1 IIntID using "`ARTDate'" , keep(1 3) nogen 
distinct ACDIS_IIntID 

** Keep only viral loads
keep if LabTestCode=="VL"
rename RESULT ViralLoad
sum ViralLoad, d

** In 2011, VL or 1 or 40 is undetectable
if "$VLImpute"=="Yes" {
  set seed 339487734
  gen RandomUndetectable =ceil(1550*runiform()) if ViralLoad <=40
  replace ViralLoad = RandomUndetectable if ViralLoad<=40
} 

** Keep specific years
gen TestYear = year(TestDate)
keep if inlist(TestYear, 2011)
distinct IIntID 

bysort IIntID: egen Age1 = min(AgeTested)
keep if inrange(Age1, 15, 100)
gen Female = (Sex==2)
egen AgeGrp = cut(Age1), at(15, 20, 25, 30, 35, 40, 45, 55, 100) icode label

** Ok, multiple VL by indiv
preserve
collapse (firstnm) ViralLoad, by(IIntID)
tempfile FVL_mn
save "`FVL_mn'" 
restore

bysort IIntID (TestDate): keep if _n==1
drop ViralLoad 
merge 1:1 IIntID using "`FVL_mn'", nogen

gen DetectVL = (ViralLoad>1550)
keep IIntID Female AgeGrp ViralLoad DetectVL 
saveold "$derived/FVLdat", replace 

***********************************************************************************************************
********************************************* Community VL ************************************************
***********************************************************************************************************
use "$AC_Data/Individuals/2015/RD01-01_ACDIS_Individuals", clear
gen Female = (Sex==2)
keep IIntID DateOfBirth Female 
duplicates drop IIntID, force
tempfile Individuals
save "`Individuals'"

insheet using "$source/CommunityViralLoadWithARtemisData29jun2013.csv", clear 
fdate datereceivedatacvl, sfmt("YMD")
rename datereceivedatacvl TestDate
rename iintid IIntID 

set seed 339487731
gen RandomUndetectable =int(1500*runiform()) if vlbelowldl == "Yes"
replace vlresultcopiesml =RandomUndetectable if  vlbelowldl =="Yes"
rename vlresultcopiesml ViralLoad
drop if missing(ViralLoad)

** Get Sex and other  vars
merge m:1 IIntID using "`Individuals'" , keep(match) nogen

gen Age = 2011 - year(DateOfBirth)
egen AgeGrp = cut(Age), at(15, 20, 25, 30, 35, 40, 45, 55, 150) icode label
gen DetectVL = (ViralLoad>1550)

keep IIntID Female ViralLoad Age* DetectVL

saveold "$derived/CVLdat", replace 




