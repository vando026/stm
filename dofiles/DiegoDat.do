//  program:    Diego.do
//  task:	Make datasets for Diego
//  project:	Name
//  author:     AV / Created: 17May2016 


** 1) Cumulative incidence, clear diff in age, 80% life time risk of acquiring infection for females 
** 60% for females
** 2) transform quinn index
** 3) HIv negatives get assigned zero probability if they tested negative in 2011. for all data

** This dataset comes from HIVSurveillance.do
use "`HIVDat0'", clear

** Ok if latest HIV neg before 2011 and no Pos drop
drop if year(LatestHIVNegative) < 2011 & missing(EarliestHIVPositive)

** Any neg test between 2011 onward, still negative
gen Neg2011 = inrange(year(EarliestHIVNegative), 2011, 2015)
replace Neg2011 = 1 if inrange(year(LatestHIVNegative), 2011, 2015)

** ok Indentify if pos before 2011
gen HIVPositive2011 = (year(EarliestHIVPositive)<=2011 | year(LatestHIVPositive)<=2011)
tab HIVPositive2011

tempfile HIV2011
save "`HIV2011'" 

***********************************************************************************************************
***********************************************************************************************************
***********************************************************************************************************
** Bring in BSIntID 
use "$source/DemographyYear", clear
keep BSIntID IIntID ExpYear Episode Age Sex ExpDays

keep if ExpYear==2011
drop if missing(BSIntID)

** Identify BS that ID spent most time in in 2011
bysort IIntID : egen MaxBS = max(ExpDays)
bysort IIntID: gen MaxBSID = BSIntID if (MaxBS==ExpDays)
drop BSIntID
bysort IIntID: egen BSIntID = max(MaxBSID)
duplicates drop IIntID, force

drop if Age < 15
gen Female = (Sex==2)
drop Max* Episode* Exp* Sex
egen AgeGrp = cut(Age), at(15, 20, 25, 30, 35, 40, 45, 100) icode label

duplicates list IIntID 
tempfile Diego
save "`Diego'" 

***********************************************************************************************************
**************************************** VL data **********************************************************
***********************************************************************************************************
use "`Diego'", clear
merge m:1 IIntID using "`HIV2011'", keepusing(HIVPositive2011) nogen keep(match) 

merge 1:m IIntID using "$derived/PVL2011", nogen keepusing(Data) keep(1 3)
outsheet using "$derived\Ind_PVL.xls", replace

foreach dat in CVL {
  ds ViralLoad`dat'

  preserve
  ** We drop any missing VL
  drop if missing(ViralLoad`dat') & HIVPositive2011==1
  replace ViralLoad`dat' = 0 if missing(ViralLoad`dat') & HIVPositive2011==0
  collapse (mean) ViralLoad`dat' , by(BSIntID)

  gen Quin_`dat' = 0 if inrange(ViralLoad`dat', 0 , 1550)
  replace Quin_`dat' = 2.5 if inrange(ViralLoad`dat', 1551, 3500) 
  replace Quin_`dat' = 12 if inrange(ViralLoad`dat', 3501, 10000 ) 
  replace Quin_`dat' = 13.5 if inrange(ViralLoad`dat', 10001, 50000 ) 
  replace Quin_`dat' = 23 if ViralLoad`dat' > 50000 & !missing(ViralLoad`dat')
  ** outsheet using "$derived\BS_`dat'.xls", replace
  restore
}

use "$derived/PVL2011", clear 

gen Quin_ = 0 if inrange(ViralLoad, 0 , 1550)
replace Quin_ = 2.5 if inrange(ViralLoad, 1551, 3500) 
replace Quin_ = 12 if inrange(ViralLoad, 3501, 10000 ) 
replace Quin_ = 13.5 if inrange(ViralLoad, 10001, 50000 ) 
replace Quin_ = 23 if ViralLoad > 50000 & !missing(ViralLoad)

bysort Data: tab Quin_

***********************************************************************************************************
**************************************** Quinn ************************************************************
***********************************************************************************************************
** Note 28Jul2016: New data for Diego, give survey data linked to BS
use "`Diego'", clear
merge 1:m IIntID using "$derived/PVL2011", nogen keepusing(Data ViralLoad) keep(match)
drop AgeGrp
outsheet using "$derived\VL_Ind.xls", replace

