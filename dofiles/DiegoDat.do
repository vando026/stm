//  program:    Diego.do
//  task:	Make datasets for Diego
//  project:	Name
//  author:     AV / Created: 17May2016 

***********************************************************************************************
**************************************** Dofile ***********************************************
***********************************************************************************************
** This prepares earlier datasets
do "$dofile/cvl-manage.do"

***********************************************************************************************
**************************************** coordinates ******************************************
***********************************************************************************************
import excel using "$source/Viral_load_estimation_Oct22.xls", clear firstrow 
keep BSIntID Longitude Latitude 
duplicates list BSIntID 
duplicates drop Latitude Longitude, force
outsheet using "$derived\BSIntID_Coords.csv", replace comma
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
label drop lblHIVResult

tab HIVResult 
drop VisitDate
tempfile HIV
save "`HIV'" 

***********************************************************************************************
**************************************** Weights **********************************************
***********************************************************************************************
use "`HIV'", clear
drop if missing(BSIntID)
tab Female AgeGrp , row
collapse (count) Count=IIntID , by(Female AgeGrp)
bysort Female: egen Total = total(Count)
gen Proportion = Count/Total
tempfile WeightN
save "`WeightN'" 
outsheet using "$derived\HIV2011_weightsFemale.csv", replace comma

use "`HIV'", clear
drop if missing(BSIntID)
collapse (count) Count=IIntID , by(AgeGrp)
egen Total = total(Count)
gen Proportion = Count/Total
tempfile WeightN
save "`WeightN'" 
outsheet using "$derived\HIV2011_weights.csv", replace comma


***********************************************************************************************
**************************************** Create CVL data **************************************
***********************************************************************************************
use "`HIV'", clear
merge 1:m IIntID using "$derived/CVLdat", keepusing(ViralLoad) nogen

replace ViralLoad = 0 if HIVResult==0
drop if missing(ViralLoad)
drop if missing(BSIntID)

** PDV
gen DetectViremia = (ViralLoad>=1500 & !missing(ViralLoad))
sum DetectViremia 

** TI
gen log10VL = log10(ViralLoad)
gen _TR = (2.45)^(log10VL - log10(150)) if ViralLoad>150
gen _beta = 0.003 * _TR
gen TransIndex = (1-(1- _beta)^100)
replace TransIndex = 0 if missing(TransIndex)
sum TransIndex 

** Bring in coordinates
merge m:1 BSIntID using "`Cord'", // keep(match) nogen 
drop _* 

order BSIntID Longitude Latitude IIntID
outsheet using "$derived\Ind_PVL_All_$today.csv", replace comma


***********************************************************************************************
****************************************FVL ***************************************************
***********************************************************************************************
use "`HIV'", clear
merge 1:m IIntID using "$derived/FVLdat", nogen keepusing(ViralLoad)
drop if missing(BSIntID)

** This gives number of negs and pos tested in 2011
replace ViralLoad = 0 if HIVResult==0
drop if missing(ViralLoad)

outsheet using "$derived\Ind_FVL_All_$today.xls", replace
