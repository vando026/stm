//  program:    cvl-analysis3.do
//  task:	Do quartiles
//  project:	Name
//  author:     AV / Created: 23Oct2016 

***********************************************************************************************************
**************************************** Get populations weights ******************************************
***********************************************************************************************************
** Only for 2011?
use "$source/RD02-002_Demography", clear

** Dont need any obs other than 2011
keep BSIntID IIntID ExpYear
** Resident in BS in this year, drop if not
drop if missing(BSIntID)
duplicates drop IIntID, force 
keep if inrange(ExpYear, 2004, 2015)

** You must run cvl-manage2.do first
merge m:1 IIntID using "`Individuals'",  keep(match)

gen Keep = . 
replace Keep = 1 if inrange(Age, 15, 55) & Female == 0
replace Keep = 1 if inrange(Age, 15, 50) & Female == 1
keep if Keep == 1
drop Keep

** Make Age Category 
egen AgeGrp1 = cut(Age), at(15(5)45, 100) label icode
keep IIntID AgeGrp1 Female
collapse (count) N=IIntID, by(AgeGrp1)
tempfile PopStand
save "`PopStand'" 

use "`DiegoData'", clear
keep if Data=="CVL"
rename  AgeGrp AgeGrp1
collapse (count) n=IIntID, by(AgeGrp1)
merge 1:1 AgeGrp1 using "`PopStand'" , nogen
gen Weight = N/n
gen fpc = 1/Weight
egen Total = total(N) 
gen pWeight = N/Total
drop Total
tempfile PopWeights
save "`PopWeights'" 

***********************************************************************************************************
**************************************** Quartiles ********************************************************
***********************************************************************************************************
clear
set obs 1 
gen x = 1
tempfile QDat
save "`QDat'" 

local vars G_MVL PDV TI G_PVL P_TI P_PDV 
foreach var of local vars {
  use "$derived/cvl-analysis2", clear
  gen ID = _n
  qui stset  EndDate, failure(SeroConvertEvent==1) entry(EarliestHIVNegative) ///
    origin(EarliestHIVNegative) scale(365.25) exit(EndDate) id(ID)
  qui egen Q = xtile(`var'), n(4)
  strate Q Female, per(100) output("$output/`var'", replace)
  use "$output/`var'", clear
  gen Label = "`var'"
  rename _Rate rate
  rename  _Lower lb
  rename _Upper ub
  tempfile Q`var'
  save "`Q`var''" , replace
  use "`QDat'", clear
  append using "`Q`var''"
  save "`QDat'", replace
}

use "`QDat'", clear
drop in 1
drop x _*
outsheet * using "$output\StdQuartile.txt", replace
** outsheet * using "$output\StdQuartileNoFEM.txt", replace

***********************************************************************************************
**************************************** Calc estimates ***************************************
***********************************************************************************************
use "$derived/cvl-analysis2", clear
gen ID = _n
stset  EndDate, failure(SeroConvertEvent==1) entry(EarliestHIVNegative) ///
  origin(EarliestHIVNegative) scale(365.25) exit(EndDate) id(ID)
gen PTime = (EndDate - EarliestHIVNegative)/365.25
keep IIntID SeroConvertEvent Female AgeGrp1 PTime $CVL _*
global CVL G_MVL G_PVL PDV P_PDV TI P_TI


merge m:1 AgeGrp1 using "`PopWeights'", nogen
foreach var of global CVL {
  capture drop Q_`var'
  dis as text "=============> `var'"
  egen Q_`var' = xtile(`var'), n(4)
  svyset IIntID [pweight=Weight], strata(Q_`var') vce(linearized) singleunit(missing) 
  svy: ratio (SeroConvertEvent/PTime), stdize(AgeGrp1) stdweight(Weight) over(Q_`var')
  strate Q_`var' Female , per(100)
}


