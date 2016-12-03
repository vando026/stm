//  program:    analysis2.do
//  task:	This is the analysis file for CVL cox model
//  project:	CVL
//  author:     AV / Created: 03Feb2016 

***********************************************************************************************************
**************************************** Single Rec Data **************************************************
***********************************************************************************************************
** log using "$output/Output$today.txt", replace text 
use "$derived/cvl-analysis2", clear

gen ID = _n
stset  EndDate, failure(SeroConvertEvent==1) entry(EarliestHIVNegative) ///
  origin(EarliestHIVNegative) scale(365.25) exit(EndDate) id(ID)

** Set covariates here once, so you dont have to do it x times for x models
global prev "i.HIV_pcat"
global urban "ib1.urban"
global vars "Female i.AgeGrp1 ib1.urban ib1.Marital ib0.PartnerCat ib1.AIQ"

***********************************************************************************************************
**************************************** No Negatives *****************************************************
***********************************************************************************************************
foreach var of varlist G_MVL PDV TI {
  dis as text _n "=========================================> Showing for `var'"
  stcox `var', noshow
  stcox `var' $vars, noshow
  ** stcox `var' $urban $vars, noshow
  ** stcox `var' $prev $urban $vars, noshow
} 

foreach var of varlist G_PVL P_PDV P_CTI {
  dis as text _n "=========================================> Showing for `var'"
  ** stcox `var', noshow
  ** stcox `var' $vars, noshow
  stcox `var' $urban $vars, noshow
  ** stcox `var' $prev $urban $vars, noshow
} 
** stcox $prev
** log close

***********************************************************************************************************
***************************************** PVL Vars ********************************************************
***********************************************************************************************************
global CVL G_MVL PDV TI 
foreach mod of global CVL   {
  eststo `mod': stcox `mod' $vars , noshow
  mat `mod' = r(table)
  mat `mod' = `mod'[1..6,1]'
}

global opts1 "cells("b(fmt(%9.3f)) ci(par(( - ))) p") substitute(0.000 "<0.001") compress"
global opts2 "eform varwidth(12) modelwidth(6 13 6) nonumbers nogaps replace"
global opts3 "mlabels("Model 1" "Model 2" "Model 3")"
global opts4 order($CVL)
global opts6 "drop(0.HIV_pcat 0.AgeGrp1 1.urban 1.Marital 0.PartnerCat 1.AIQ)"
local opts5 "csv"
esttab $CVL using "$output/Model1.`opts5'", $opts1 $opts2 $opts3 $opts4 `opts5' 

***********************************************************************************************************
***************************************** P_PVL vars ******************************************************
***********************************************************************************************************
global PCVL G_PVL P_PDV P_TI 
foreach mod of global PCVL {
  eststo `mod': stcox `mod' $vars , noshow
  mat `mod' = r(table)
  mat `mod' = `mod'[1..6,1]'
}

global opts4 order($PCVL)
esttab $PCVL using "$output/Model2.`opts5'", $opts1 $opts2 $opts3 $opts4 `opts5' 


***********************************************************************************************************
**************************************** FVL vars *********************************************************
***********************************************************************************************************
global FVL G_FVL FVL_PDV FVL_TI
foreach mod of global FVL {
  eststo `mod': stcox `mod' $vars, noshow
}
global opts4 order($FVL)
esttab $FVL using "$output/Model3.`opts5'", $opts1 $opts2 $opts3 $opts4 `opts5' 


***********************************************************************************************************
**************************************** Compare model fit ************************************************
***********************************************************************************************************
global cvlonly ""
foreach var of global CVL {
  qui eststo `var'_only: stcox `var', noshow
  qui eststo `var'_prev: stcox `var' $prev,  noshow
  global cvlonly  $cvlonly `var'_only 
} 
eststo Prev: qui stcox $prev , noshow

** Compute AIC = -2ln L + 2(k+c), k is model parameters
mat AIC = J(4, 4, .)
** Get the model with no HIV prevalence
local i = 1
foreach mod in  Prev $cvlonly {
  dis as text "=========== Showing AIC for `mod'"
  est restore `mod'
  mat AIC[`i', 1] = -2*`=e(ll)' + 2*(`=e(df_m)' + 1)
local ++i
}

lrtest  G_MVL_only G_MVL_prev, force
mat AIC[2, 2] = r(p)
lrtest  PDV_only PDV_prev, force
mat AIC[3, 2] = r(p)
lrtest TI_only TI_prev, force
mat AIC[4, 2] = r(p)
mat list AIC


** PVL with prevalence
global pcvlonly ""
foreach var of global PCVL {
  qui eststo `var'_only: stcox `var', noshow
  qui eststo `var'_prev: stcox  `var' $prev  , noshow
  global pcvlonly  $pcvlonly `var'_only 
} 

local i = 1
foreach mod in  Prev $pcvlonly {
  dis as text "=========== Showing AIC for `mod'"
  est restore `mod'
  mat AIC[`i', 3] = -2*`=e(ll)' + 2*(`=e(df_m)' + 1)
local ++i
}


lrtest  G_PVL_only G_PVL_prev, force
mat AIC[2, 4] = r(p)
lrtest  P_PDV_only P_PDV_prev, force
mat AIC[3, 4] = r(p)
lrtest P_TI_only P_TI_prev, force
mat AIC[4, 4] = r(p)
mat list AIC


***********************************************************************************************************
**************************************** Correlaions ******************************************************
***********************************************************************************************************
pwcorr G_PVL G_FVL, sig
pwcorr P_PDV FVL_PDV, sig
pwcorr P_TI FVL_TI, sig

***********************************************************************************************************
**************************************** Table 2 incidence ************************************************
***********************************************************************************************************
clear 
set obs 1
gen Var = .
save "$output/IncidenceOut", replace
use "$derived/cvl-analysis2", clear
gen ID = _n
stset  EndDate, failure(SeroConvertEvent==1) entry(EarliestHIVNegative) ///
  origin(EarliestHIVNegative) scale(365.25) exit(EndDate) id(ID)

stptime, per(100)

foreach var of varlist HIV_pcat Female AgeGrp1 urban Marital PartnerCat AIQ {
  strate `var', per(100) output("$output/st_`var'", replace) 
  preserve
  use "$output/st_`var'", clear
  rename `var' Var
  gen VarLab = "`var'" 
  sav "$output/st_`var'", replace
  use "$output/IncidenceOut", clear
  append using "$output/st_`var'" , force nolabel
  sav "$output/IncidenceOut", replace
  restore
}

use "$output/IncidenceOut", replace
drop if missing(Var)
replace _Y = _Y*100
replace _Y = int(_Y)
foreach var of varlist _Rate _Lower _Upper {
  replace `var' = round(`var', 0.01) 
}
order VarLab, first
export delimited using "$output\IncidenceOut.csv", replace
