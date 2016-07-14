//  program:    VL2011_12.do
//  task:		Produce VL for 2011 and 2012
//  project:	Misc
//  author:     AV / Created: 15Aug2015 

***********************************************************************************************************
**************************************** Prep Data ********************************************************
***********************************************************************************************************
** Get IIntIDs from Demograpy dataset 2014
use "$source/RD02-002_Demography", clear

** Get relevant IDs and vars
duplicates drop IIntID, force
clonevar ACDIS_IIntID = IIntID 
keep IIntID ACDIS_IIntID Sex 
distinct IIntID 

tempfile Demo
sav "`Demo'"

use "$source/ARTemisAll2013A", clear 
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

merge 1:m ACDIS_IIntID using "$source/LabResults" , keep(match) nogen keepusing(TestDate LabTestCode RESULT AgeTested) 
merge m:1 IIntID using "`ARTDate'" , keep(1 3) nogen 
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
bysort IIntID: egen DateOfInitiationMin = min(DateOfInitiation)
format DateOfInitiationMin %td
gen TestYear = year(TestDate)
keep if inlist(TestYear, 2011)

** Age
keep if inrange(AgeTested, 15, 65)

gen log10VL = log10(ViralLoad) 
gen Over50k = cond(ViralLoad>=50000, 1, 0)

drop ACDIS_IIntID 
keep IIntID Sex TestDate TestYear ViralLoad AgeTested log10VL Over50k DateOfInitiationMin
rename DateOfInitiationMin DateOfInitiation

** Save datasets 
distinct IIntID 
gen Data = "FVL"

tempfile FVLdat
save "`FVLdat'" 

***********************************************************************************************************
********************************************* Community VL ************************************************
***********************************************************************************************************
use "$source/RD01-01_ACDIS_Individuals", clear
keep IIntID DateOfBirth 
duplicates drop IIntID, force
tempfile Individuals
save "`Individuals'"

insheet using "$source/CommunityViralLoadWithARtemisData29jun2013.csv", clear 
fdate datereceivedatacvl, sfmt("YMD")

rename iintid IIntID 
rename datereceivedatacvl TestDate
gen TestYear = year(TestDate)

** Get Sex and other  vars
merge m:1 IIntID using "`Demo'" , keep(match) nogen keepusing(Sex)
merge m:1 IIntID using "`Individuals'" , keep(match) nogen
merge m:1 IIntID using "`ARTDate'" , keep(1 3) nogen 

gen AgeTested = int((TestDate - DateOfBirth)/365.25) 

set seed 339487731
gen RandomUndetectable =int(1500*runiform()) if vlbelowldl == "Yes"
replace vlresultcopiesml =RandomUndetectable if  vlbelowldl =="Yes"
rename vlresultcopiesml ViralLoad
drop if missing(ViralLoad)

gen log10VL = log10(ViralLoad)
gen Over50k = cond(ViralLoad>=50000, 1, 0)

keep IIntID Sex TestDate TestYear ViralLoad AgeTested DateOfInitiation log10VL Over50k
gen Data = "CVL"

tempfile CVLdat
save "`CVLdat'" 

***********************************************************************************************************
**************************************** Merge CVL and FVL data *******************************************
***********************************************************************************************************
use "`FVLdat'", clear
append using "`CVLdat'"

** Ok, multiple VL by indiv
bysort IIntID Data: egen VLmn = mean(ViralLoad)
replace  VLmn = floor(VLmn)
collapse (firstnm) ViralLoad = VLmn AgeTested Sex, by(IIntID Data )

bysort IIntID: egen Age1 = min(AgeTested)

egen AgeTestedVL = cut(Age1), at(15, 20, 25, 30, 35, 40, 45, 100) icode label
gen Female = (Sex==2)

drop Sex Age1 AgeTested
** reshape wide ViralLoad , i(IIntID) j(Data) string

saveold "$derived/PVL2011", replace


