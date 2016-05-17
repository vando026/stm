//  program:    cvl-manage2.do
//  task:	Prep cvl data for analysis
//  project:	Name
//  author:     AV / Created: 30Jan2016 

***********************************************************************************************************
**************************************** Bring in Datasets*************************************************
***********************************************************************************************************
import excel using "$source/Viral load estimations.xls", clear firstrow 

** I have to format vars from Diego file
qui {
  foreach var of varlist PVL_prev_v - PPDV_PVL_Males  {
    ds `var', has(type string)
    if "`=r(varlist)'" != "." {
      replace `var' = "" if `var'=="-"
      destring `var', replace
    }
    drop if missing(`var')
  }
}

** Make HIV prev
gen HIV_prev = hiv8_2011_ * 100
egen HIV_pcat = cut(HIV_prev), at(0, 12.5, 25, 100) icode label
tab HIV_pcat

drop PVL_prev_v - ART_prev_1 

foreach var of varlist FVL_unadjusted  - PVL_males_15 {
  qui replace `var' = `var'/1000
}

tempfile Point
save "`Point'"



***********************************************************************************************************
**************************************** Individuals ******************************************************
***********************************************************************************************************
use "$source/RD01-01_ACDIS_Individuals", clear
keep IIntID DateOfBirth 
duplicates drop IIntID, force
tempfile Individuals
save "`Individuals'"


***********************************************************************************************************
**************************************** Demography *******************************************************
***********************************************************************************************************
** Bring in linked Demography data
use "$source/RD02-002_Demography", clear

** Dont need any obs other than 2011
keep if ExpYear == 2011

keep IIntID BSIntID Sex ExpDays
drop if missing(BSIntID)

** Drop duplicates as same BS per 1+ episode in 2011
** duplicates drop IIntID BSIntID, force
bysort IIntID  : gen Count = _N
tab Count

** Identify BS that ID spent most time in in 2011
bysort IIntID : egen MaxBS = max(ExpDays)
bysort IIntID: gen MaxBSID = BSIntID if (MaxBS==ExpDays)
collapse (firstnm) MaxBSID Sex, by(IIntID)
rename MaxBSID BSIntID

** Bring in CVL, no match for BSIntId 17887
merge m:1 BSIntID using "`Point'", keep(match) nogen 

encode(IsUrbanOrR) if IsUrbanOrR != "DFT", gen(urban)
drop IsUrbanOrR 
tempfile BS_dat
save "`BS_dat'" 

***********************************************************************************************************
**************************************** Single Rec HIV data***********************************************
***********************************************************************************************************
***********************************************************************************************************
use "$derived/ac-HIV_Dates_2011", clear

** Bring in CVL data
merge 1:m IIntID using "`BS_dat'", keep(match) nogen
distinct IIntID 

** Bring in ages. 
merge m:1 IIntID using "`Individuals'" , keepusing(DateOfBirth) keep(match) nogen

gen Age = round((date("01-01-2011", "DMY")-DateOfBirth)/365.25, 1)
global ad = 12
drop if Age < $ad

** Make Age Category 
egen AgeGrp = cut(Age), at($ad, 20(5)90, 110) label icode
** Make this for AgeSex var
egen AgeGrp1 = cut(Age), at($ad, 20(5)45, 110) label icode

** Make new AgeSex Var
gen Female = (Sex==2)
gen SexLab = cond(Sex==2, "F", "M")

saveold "$derived/cvl-main2", replace

