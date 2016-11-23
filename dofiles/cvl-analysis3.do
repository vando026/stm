//  program:    cvl-analysis3.do
//  task:	Do quartiles
//  project:	Name
//  author:     AV / Created: 23Oct2016 

***********************************************************************************************************
**************************************** Get populations weights ******************************************
***********************************************************************************************************
** Only for 2011?
use "`Diego'", clear
collapse (count) N=IIntID, by(AgeGrp1 Female)
tempfile PopStand
save "`PopStand'" 

use "$derived/cvl-analysis2", clear
duplicates drop IIntID, force  
collapse (count) n=IIntID, by(AgeGrp1 Female)
merge 1:1 Female AgeGrp1 using "`PopStand'" , nogen
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
  ** strate Q , per(100) output("$output/`var'", replace)
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
** outsheet * using "$output\StdQuartileNoFEM.txt", replace
sort Label Female Q
outsheet * using "$output\StdQuartile.txt", replace

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
  strate Q_`var' , per(100)
}

***********************************************************************************************
**************************************** Direct Standard **************************************
***********************************************************************************************
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
  strate Q AgeGrp1, per(100) output("$output/`var'", replace)
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
merge m:1 AgeGrp1 using "`PopWeights'", nogen 
sort Label AgeGrp1 Q 
gen std_rate = rate * pWeight
collapse (sum) std_rate, by(Label Q)
tempfile StdWeights
save "`StdWeights'" 
** outsheet * using "$output\StdQuartile.txt", replace
use "`StdWeights'", clear
list *

/*
egen QPDV = cut(P_PDV), at(0, 15, 20, 30, 100) icode
strate QPDV, per(100)
egen QPTI = cut(P_TI), at(0, 5, 6.5, 7.5, 100) icode
strate QPTI, per(100)


