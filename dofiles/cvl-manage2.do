//  program:    cvl-manage2.do
//  task:	Prep cvl data for analysis
//  project:	Name
//  author:     AV / Created: 30Jan2016 

***********************************************************************************************************
**************************************** Bring in Datasets*************************************************
***********************************************************************************************************
insheet using "$source/CommunityVL/RegisteredPointLocationsMI_CVL+ARTEMIS.csv", clear
rename bsintid BSIntID
tempfile Point
save "`Point'"

use "$source/Individuals/RD01-01 ACDIS Individuals", clear
keep IIntID DateOfBirth 
duplicates drop IIntID, force
tempfile Individuals
save "`Individuals'"

***********************************************************************************************************
**************************************** Demography *******************************************************
***********************************************************************************************************
use "$source/Demography/DemographyYear", clear
keep IIntID BSIntID ExpYear Obs*  Sex
drop if missing(BSIntID)

** Dont need any obs after 2011
drop if year(ObservationStart) > 2011

** Bring in repeat tester data
merge m:1 IIntID using "$derived/ac-HIV_Dates_RT_2011", keep(match) nogen 
drop Method IntervalLength IntervalLengthCat 

** Now merge point locations with BSIntId 
merge m:1 BSIntID using "`Point'", nogen keep(match)

** Bring in ages. RepeatTester datase has ages 16-55 for Males or 16-49 for females
merge m:1 IIntID using "`Individuals'", keepusing(DateOfBirth) keep(match) nogen
gen Age = round((ObservationStart-DateOfBirth)/365.25, 1)
drop if Age < 12

** Make Age Category 
egen AgeGrp = cut(Age), at(12, 20(5)90, 110) label icode
** Make this for AgeSex var
egen AgeGrp1 = cut(Age), at(12, 20(5)45, 110) label icode
tab AgeGrp1

** Make new AgeSex Var
gen SexLab = cond(Sex==2, "F", "M")
generate AgeSex=SexLab + string(AgeGrp1)

save "$derived/cvl-analysis2", replace
