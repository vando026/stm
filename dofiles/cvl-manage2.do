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
keep if ExpYear == 2011
keep IIntID BSIntID Sex
drop if missing(BSIntID)

** Dont need any obs other than 2011

** Drop duplicates as same BS per 1+ episode in 2011
duplicates drop IIntID BSIntID, force
bysort IIntID  : gen Count = _N
tab Count  //majority in 1 BSIntID 

** Bring in CVL, no match for BSIntId 17887
merge m:1 BSIntID using "`Point'", keep(match) nogen keepusing(*geo_mean* *_prev_* is*)

** lets rename these vars, too long
rename pvl_prev_vlbaboveldlyesnoincneg ppvl
rename pvl_prev_vlbaboveyesno_gauss199 ppvlg
rename pvl_geo_mean_lnvlresultcopiesml pgm
rename art_prev_vlbaboveldlyesnoincneg apvl
rename art_geo_mean_lnvlresultcopiesml agm
rename art_prev_vlaboveldlyesno2011    apvlg //??

encode(isurbanorrural) if isurbanorrural != "DFT", gen(urban)

** What about being in 1+ BSIntId in 2011? For now take max, and
** associate BSIntID with max
foreach var of varlist ppvl-apvlg {
  bysort IIntID : egen _`var' = max(`var')
  ** This identified BS of max value
  qui bysort IIntID : egen BS`var' = max(cond(_`var' == `var', BSIntID, 0))
  qui bysort IIntID : egen urb`var' = max(cond(_`var' == `var', urban, 0))
  label values urb`var' urban
  drop `var'
  rename _`var' `var'
}

** Now drop the duplicate ID since we only have one val by year 2011
duplicates drop IIntID, force 
drop Count

merge 1:m IIntID using "$derived/HIV_Episodes", keep(match)
distinct IIntID if SeroConvertEvent==1
distinct IIntID 

***********************************************************************************************************
****************************************  Get Age *********************************************************
***********************************************************************************************************
** Bring in ages. RepeatTester datase has ages 16-55 for Males or 16-49 for females
merge m:1 IIntID using "`Individuals'", keepusing(DateOfBirth) keep(match) nogen

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

save "$derived/cvl-analysis2", replace
