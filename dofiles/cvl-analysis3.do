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
collapse (count) N=IIntID, by(AgeGrp1 Female)
gen PTime = N * 365.25
tempfile PopStand
save "`PopStand'" 

***********************************************************************************************************
**************************************** Quartiles ********************************************************
***********************************************************************************************************
use "$derived/cvl-analysis2", clear

gen ID = _n
stset  EndDate, failure(SeroConvertEvent==1) entry(EarliestHIVNegative) ///
  origin(EarliestHIVNegative) scale(365.25) exit(EndDate) id(ID)

egen Log_MVL_q = xtile(Log_MVL), n(4)
strate Log_MVL_q AgeGrp1 Female, per(100) output("$output/MVL", replace)
strate Log_MVL_q if Female==1 , per(100) 
strate Log_MVL_q if Female==0 , per(100) 

use "$output/MVL", clear
merge m:1 Female AgeGrp1 using "`PopStand'", nogen
collapse (mean) std_inc_rate = _Rate [fweight = N], by(Log_MVL_q Female)


foreach var of varlist Log_MVL PDV TI {
  egen `var'_q = xtile(`var'), n(4)
  strate `var'_q, per(100) output("$output/`var'", replace)
}


mat define Out = J(1, 5, .)
  dis as text _n "=========== `var'"
  cap drop `var'_q
  forvalue m = 0/1 {
    forvalue i = 1/4 {
    qui stptime if `var'_q==`i' & Female==`m', per(100) dd(2) 
      mat define `var'`i' = J(1, 5, .)
      mat rownames `var'`i' = "`var'`i'`m'"
      mat `var'`i'[1, 1] = `i'
      mat `var'`i'[1, 2] = `m'
      mat `var'`i'[1, 3] = r(rate) 
      mat `var'`i'[1, 4] = r(lb)
      mat `var'`i'[1, 5] = r(ub)
      mat Out = Out \ `var'`i'
    }
  }
}
mat Out =  Out[2..., 1...]
mat colnames Out = Q Female Rate lb ub
mat2txt , matrix(Out) saving("$output/coefMat.txt") replace 
