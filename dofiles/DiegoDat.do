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
global dropNeg = "No"
use "`Diego'", clear
merge m:1 IIntID using "`HIV2011'", keepusing(HIVPositive2011) nogen keep(match) 

merge 1:m IIntID using "$derived/PVL2011", nogen keepusing(Data ViralLoad) keep(1 3)

** Note 05Sep2016: Frank says to forget FVL for now
drop if Data == "FVL"

replace ViralLoad = 0 if HIVPositive2011==0
drop if missing(ViralLoad)

if "$dropNeg"=="Yes" {
  local Dat = "PosOnly"
  drop if ViralLoad==0
} 
else {
  local Dat = "All"
}

** collapse (mean) ViralLoad mean(), by(BSIntID)

gen Quin = 0 if inrange(ViralLoad, 0 , 1550)
replace Quin = 2.5 if inrange(ViralLoad, 1551, 3500) 
replace Quin = 12 if inrange(ViralLoad, 3501, 10000 ) 
replace Quin = 13.5 if inrange(ViralLoad, 10001, 50000 ) 
replace Quin = 23 if ViralLoad > 50000 & !missing(ViralLoad)

outsheet using "$derived\Ind_PVL_`Dat'_$today.xls", replace

***********************************************************************************************************
**************************************** Quinn ************************************************************
***********************************************************************************************************
** Note 28Jul2016: New data for Diego, give survey data linked to BS
use "`Diego'", clear
merge 1:m IIntID using "$derived/PVL2011", nogen keepusing(Data ViralLoad) keep(match)
drop AgeGrp
outsheet using "$derived\VL_Ind.xls", replace

