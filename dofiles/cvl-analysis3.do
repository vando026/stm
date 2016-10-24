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
keep if ExpYear >= 2011

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
keep if Female==1
collapse (count) N=IIntID, by(AgeGrp1)
tempfile PopStand
save "`PopStand'" 

***********************************************************************************************************
**************************************** Quartiles ********************************************************
***********************************************************************************************************
clear
set obs 1 
gen x = 1
tempfile QDat
save "`QDat'" 

local vars Log_MVL PDV TI Log_PVL P_TI P_PDV 
foreach var of local vars {
  use "$derived/cvl-analysis2", clear
  gen ID = _n
  qui stset  EndDate, failure(SeroConvertEvent==1) entry(EarliestHIVNegative) ///
    origin(EarliestHIVNegative) scale(365.25) exit(EndDate) id(ID)
  qui sum `var', d
  local p50 = r(p50)
  local p25 = r(p25)
  local p75 = r(p75)
  qui egen Q = xtile(`var'), n(4)
  strate Q Female, per(100) output("$output/`var'", replace)
  use "$output/`var'", clear
  gen p50 = `p50'
  gen p25 = `p25'
  gen p75 = `p75'
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
sort Label Female Q
export delimited using "$output\StdQuartile.txt", delimiter(tab) replace

use "$derived/cvl-analysis2", clear
gen ID = _n
qui stset  EndDate, failure(SeroConvertEvent==1) entry(EarliestHIVNegative) ///
  origin(EarliestHIVNegative) scale(365.25) exit(EndDate) id(ID)
gen PTime = (EndDate - EarliestHIVNegative)/365.25
egen Q = xtile(Log_MVL), n(4)
collapse (count) sampN=IIntID (sum) D=SeroConvertEvent Y=PTime if Female==1, by(Q AgeGrp1) 
merge m:1 AgeGrp1 using "`PopStand'", nogen
gen fpc=sampN/N
svyset  
svy: ratio (Test: D/Y), stdize(AgeGrp1) stdweight(N) over(Q)


