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
** Bring in linked Demography data
use "$AC_Data/Derived/Demography/RD02-002_Demography", clear

** Dont need any obs other than 2011
keep if ExpYear == 2011

keep IIntID BSIntID Sex
drop if missing(BSIntID)

** Drop duplicates as same BS per 1+ episode in 2011
duplicates drop IIntID BSIntID, force
bysort IIntID  : gen Count = _N
tab Count

** Bring in CVL, no match for BSIntId 17887
merge m:1 BSIntID using "`Point'", keep(match) nogen keepusing(*geo_mean* *_prev_* is*)

** lets rename these vars, too long
rename pvl_prev_vlbaboveldlyesnoincneg ppvl
rename pvl_prev_vlbaboveyesno_gauss199 ppvlg
rename pvl_geo_mean_lnvlresultcopiesml pgm
rename art_prev_vlbaboveldlyesnoincneg apvl
rename art_geo_mean_lnvlresultcopiesml agm
rename art_prev_vlaboveldlyesno2011    apvlg //??
rename hiv8_2011_prev_trim_1 HIV_prev

foreach var of varlist ppvl-apvl {
  sum `var'
}

encode(isurbanorrural) if isurbanorrural != "DFT", gen(urban)
save "$derived/cvl-BS_dat", replace

***********************************************************************************************************
***************************************** EPisodes HIV data ***********************************************
***********************************************************************************************************
** use "$derived/HIV_Episodes", clear 
** merge m:1 IIntID using "$derived/cvl-BS_dat", keep(match)
** distinct IIntID if SeroConvertEvent==1

***********************************************************************************************************
**************************************** Single Rec HIV data***********************************************
***********************************************************************************************************
***********************************************************************************************************
use "$derived/ac-HIV_Dates_2011", clear
gen LatestObservationDate = cond(SeroConvertEvent==1, DateSeroConvert, LatestHIVNegative)
format LatestObservationDate %td

merge 1:m IIntID using "$derived/cvl-BS_dat", keep(match) nogen
distinct IIntID 

** Bring in ages. RepeatTester datase has ages 16-55 for Males or 16-49 for females
merge m:1 IIntID using "`Individuals'" , keepusing(DateOfBirth) keep(match) nogen

gen Age = round((date("01-01-2011", "DMY")-DateOfBirth)/365.25, 1)
global ad = 12
drop if Age < $ad

** Make Age Category 
egen AgeGrp = cut(Age), at($ad, 20(5)90, 110) label icode
** Make this for AgeSex var
egen AgeGrp1 = cut(Age), at($ad, 20(5)45, 110) label icode
tab AgeGrp1

** Make new AgeSex Var
gen SexLab = cond(Sex==2, "F", "M")
generate AgeSex=SexLab + string(AgeGrp1)
encode AgeSex, gen(AgeSexCat)

** Recode vars for analysis
gen logpgm = log(pgm)
gen ppvl_pc = ppvl*100
gen ppvlg_pc = ppvl*100

gen logagm = log(agm)
gen apvl_pc = apvl*100
gen apvlg_pc = apvl*100

** Cannot use i.var stata formate for stpm
tab AgeSexCat, gen(AF)
tab urban, gen(U)

save "$derived/cvl-analysis2", replace

