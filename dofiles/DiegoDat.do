//  program:    Diego.do
//  task:	Make datasets for Diego
//  project:	Name
//  author:     AV / Created: 17May2016 

***********************************************************************************************************
**************************************** HIV data **********************************************************
***********************************************************************************************************
use "$source/RD05-001_ACDIS_HIV", clear
keep IIntID BSIntID VisitDate HIVResult Sex AgeAtVisit
keep if year(VisitDate) == 2011
egen AgeGrp = cut(AgeAtVisit), at(15, 20, 25, 30, 35, 40, 45, 55, 150) icode label
keep if inlist(HIVResult, 0, 1)

** This gives the weights for Diego, to use with Ind_PVL_All_Date dataset
preserve
drop if missing(BSIntID) 
restore

tab HIVResult 
drop VisitDate
tempfile HIV
save "`HIV'" 

***********************************************************************************************
**************************************** Create CVL data **************************************
***********************************************************************************************
use "`HIV'", clear
merge 1:m IIntID using "`CVLdat'", keepusing(ViralLoad) nogen

replace ViralLoad = 0 if HIVResult==0
drop if missing(ViralLoad)
drop if missing(BSIntID)

** This gives number of negs and pos tested in 2011
gen Quin = 0 if inrange(ViralLoad, 0 , 1550)
replace Quin = 2.5 if inrange(ViralLoad, 1551, 3500) 
replace Quin = 12 if inrange(ViralLoad, 3501, 10000 ) 
replace Quin = 13.5 if inrange(ViralLoad, 10001, 50000 ) 
replace Quin = 23 if ViralLoad > 50000 & !missing(ViralLoad)

outsheet using "$derived\Ind_PVL_All_$today.xls", replace
gen Over1500 = cond(ViralLoad>=1500, 1, 0)
sum Over1500 


***********************************************************************************************
****************************************FVL ***************************************************
***********************************************************************************************
use "`HIV'", clear
merge 1:m IIntID using "`FVLdat'", nogen keepusing(ViralLoad)
drop if missing(BSIntID)

** This gives number of negs and pos tested in 2011
replace ViralLoad = 0 if HIVResult==0
drop if missing(ViralLoad)

gen Quin = 0 if inrange(ViralLoad, 0 , 1550)
replace Quin = 2.5 if inrange(ViralLoad, 1551, 3500) 
replace Quin = 12 if inrange(ViralLoad, 3501, 10000 ) 
replace Quin = 13.5 if inrange(ViralLoad, 10001, 50000 ) 
replace Quin = 23 if ViralLoad > 50000 & !missing(ViralLoad)

outsheet using "$derived\Ind_FVL_All_$today.xls", replace
