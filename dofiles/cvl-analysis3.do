//  program:    cvl-analysis3.do
//  task:	Do quartiles
//  project:	Name
//  author:     AV / Created: 23Oct2016 


***********************************************************************************************************
**************************************** Quartiles ********************************************************
***********************************************************************************************************
global std "yes"
clear
set obs 1 
gen x = 1
tempfile QDat
save "`QDat'" 

local vars G_MVL PDV TI G_PVL P_CTI P_PDV 
** local vars P_PDV
foreach var of local vars {
  use "$derived/cvl-analysis2", clear
  gen ID = _n
  qui stset  EndDate, failure(SeroConvertEvent==1) entry(EarliestHIVNegative) ///
    origin(EarliestHIVNegative) scale(365.25) exit(EndDate) id(ID)
  qui egen Q = xtile(`var'), n(4)
  if "$std"=="yes" {
    strate Q Female AgeGrp1, per(100) output("$output/`var'", replace)
  } 
  else {
    strate Q Female , per(100) output("$output/`var'", replace)
  }
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
drop x 
rename AgeGrp1 AgeGrp
keep Q Female AgeGrp _D _Y  Label
rename _D D
rename _Y PY
merge m:1 Female AgeGrp using "`WeightN'", keep(match) nogen keepusing(Count)
outsheet * using "$output\StdQuartile.txt", replace


