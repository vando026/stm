//  program:    Diego.do
//  task:	Make datasets for Diego
//  project:	Name
//  author:     AV / Created: 17May2016 


***********************************************************************************************
**************************************** coordinates ******************************************
***********************************************************************************************
import excel using "$source/Viral_load_estimation_Oct22.xls", clear firstrow 
keep BSIntID Longitude Latitude 
duplicates list BSIntID 
tempfile Cord
save "`Cord'" 

***********************************************************************************************************
**************************************** HIV data **********************************************************
***********************************************************************************************************
use "$source/RD05-001_ACDIS_HIV", clear
gen Female = (Sex==2)
drop if AgeAtVisit < 15
keep IIntID Female BSIntID VisitDate HIVResult AgeAtVisit
keep if year(VisitDate) == 2011
egen AgeGrp = cut(AgeAtVisit), at(15, 20, 25, 30, 35, 40, 45, 55, 150) icode label
keep if inlist(HIVResult, 0, 1)

tab HIVResult 
drop VisitDate
tempfile HIV
save "`HIV'" 

***********************************************************************************************
**************************************** Weights **********************************************
***********************************************************************************************
use "`HIV'", clear
drop if missing(BSIntID)
collapse (count) N=IIntID , by(Female AgeGrp)
tempfile WeightN
save "`WeightN'" 

use "`CVLdat'", clear
collapse (count) n=IIntID , by(Female AgeGrp)
merge 1:1 Female AgeGrp using "`WeightN'", nogen
gen fweight = N/n
gen pweight = 1/N
scalar Total = sum(N)
gen pweight1 = n/Total
tempfile Weights
save "`Weights'" 

***********************************************************************************************
**************************************** Create CVL data **************************************
***********************************************************************************************
use "`HIV'", clear
merge 1:m IIntID using "`CVLdat'", keepusing(ViralLoad) nogen

replace ViralLoad = 0 if HIVResult==0
drop if missing(ViralLoad)
drop if missing(BSIntID)

** PDV
gen Over1500 = cond(ViralLoad>=1500, 1, 0)
sum Over1500 

** CTI
gen Quin = 0 if inrange(ViralLoad, 0 , 1550)
replace Quin = 2.5 if inrange(ViralLoad, 1551, 3500) 
replace Quin = 12 if inrange(ViralLoad, 3501, 10000 ) 
replace Quin = 13.5 if inrange(ViralLoad, 10001, 50000 ) 
replace Quin = 23 if ViralLoad > 50000 & !missing(ViralLoad)

** Bring in coordinates
merge m:1 BSIntID using "`Cord'", keep(match) nogen 
merge m:1 Female AgeGrp using "`Weights'", nogen

outsheet using "$derived\Ind_PVL_All_$today.csv", replace comma


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
