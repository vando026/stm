//  program:    Diego.do
//  task:	Make datasets for Diego
//  project:	Name
//  author:     AV / Created: 17May2016 


** 1) Cumulative incidence, clear diff in age, 80% life time risk of acquiring infection for females 
** 60% for females
** 2) transform quinn index
** 3) HIv negatives get assigned zero probability if they tested negative in 2011. for all data

** This gives the prevalence
use "$source/RD05-001_ACDIS_HIV", clear
keep IIntID VisitDate HIVResult Sex
keep if year(VisitDate) == 2011

keep if inlist(HIVResult, 0, 1)
duplicates drop IIntID , force
tab HIVResult 

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

gen Female = (Sex==2)
gen Keep = . 
replace Keep = 1 if inrange(Age, 15, 55) & Female == 0
replace Keep = 1 if inrange(Age, 15, 50) & Female == 1
keep if Keep == 1
drop Keep

drop Max* Episode* Exp* Sex
egen AgeGrp = cut(Age), at(15, 20, 25, 30, 35, 40, 45, 100) icode label

tab Female
tab AgeGrp
tab Female AgeGrp, row

duplicates list IIntID 
tempfile Diego
save "`Diego'" 

***********************************************************************************************************
**************************************** VL data **********************************************************
***********************************************************************************************************
use "`Diego'", clear
merge 1:1 IIntID using "`HIV2011'", keepusing(HIVResult) nogen keep(match) 
tab HIVResult

merge 1:m IIntID using "$derived/PVL2011", nogen keepusing(Data ViralLoad) // keep(1 3)

** This gives number of negs and pos tested in 2011
tab HIVResult 
gen  HIVPositive2011 = cond(HIVResult==1, "Positive", "Negative")

replace ViralLoad = 0 if HIVResult==0
drop if missing(ViralLoad)
distinct IIntID 

gen Quin = 0 if inrange(ViralLoad, 0 , 1550)
replace Quin = 2.5 if inrange(ViralLoad, 1551, 3500) 
replace Quin = 12 if inrange(ViralLoad, 3501, 10000 ) 
replace Quin = 13.5 if inrange(ViralLoad, 10001, 50000 ) 
replace Quin = 23 if ViralLoad > 50000 & !missing(ViralLoad)

outsheet using "$derived\Ind_PVL_All_$today.xls", replace



***********************************************************************************************************
**************************************** Quinn ************************************************************
***********************************************************************************************************
** Note 28Jul2016: New data for Diego, give survey data linked to BS
use "`Diego'", clear
merge 1:m IIntID using "$derived/PVL2011", nogen keepusing(Data ViralLoad) keep(match)
tempfile DiegoData
save "`DiegoData'" 
outsheet using "$derived\VL_Ind.xls", replace


