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
global vars "Female i.AgeGrp1 ib1.urban ib1.Marital ib0.PartnerCat ib1.AIQ"

***********************************************************************************************************
**************************************** No Negatives *****************************************************
***********************************************************************************************************
foreach var of varlist MVL PDV TI {
  dis as text _n "=========================================> Showing for `var'"
  stcox `var', noshow
  stcox `var' $vars, noshow
  stcox `var' $prev $vars, noshow
} 

foreach var of varlist P_MVL P_PDV P_TI {
  dis as text _n "=========================================> Showing for `var'"
  stcox `var', noshow
  ** stcox `var' $previ $vars1, noshow
  stcox `var' $vars, noshow
} 

log close

***********************************************************************************************************
***************************************** Model 1 *********************************************************
***********************************************************************************************************
foreach mod in MVL PDV TI  {
  eststo `mod': stcox `mod' $prev $vars, noshow
  mat `mod' = r(table)
  mat `mod' = `mod'[1..6,1]'
}

global opts1 "cells("b(fmt(%9.3f)) ci(par(( - ))) p") substitute(0.000 "<0.001") compress"
global opts2 "eform varwidth(12) modelwidth(6 13 6) nonumbers nogaps replace"
global opts3 "mlabels("Model 1" "Model 2" "Model 3")"
global opts4 order(MVL PDV TI)
global opts6 "drop(0.HIV_pcat 0.AgeGrp1 1.urban 1.Marital 0.PartnerCat 1.AIQ)"
local opts5 "csv"

esttab MVL PDV TI using "$output/Model1.`opts5'", $opts1 $opts2 $opts3 $opts4 `opts5' 

***********************************************************************************************************
***************************************** Model 2 *********************************************************
***********************************************************************************************************
foreach mod in P_MVL P_PDV P_TI  {
  eststo `mod': stcox `mod' $vars, noshow
  mat `mod' = r(table)
  mat `mod' = `mod'[1..6,1]'
}

global opts4 order(P_MVL P_PDV P_TI)
esttab P_MVL P_PDV P_TI using "$output/Model2.`opts5'", $opts1 $opts2 $opts3 $opts4 `opts5' 

***********************************************************************************************************
**************************************** Compare model fit ************************************************
***********************************************************************************************************
foreach var of varlist MVL PDV TI {
  eststo `var'_np: stcox `var'  $vars, noshow
} 

** Compute AIC = -2ln L + 2(k+c), k is model parameters
mat AIC = J(9, 1, .)
** Get the model with no HIV prevalence
local i = 1
foreach mod in  MVL_np PDV_np TI_np MVL PDV TI {
  dis as text "=========== Showing AIC for `mod'"
  est restore `mod'
  mat AIC[`i', 1] = -2*`=e(ll)' + 2*(`=e(df_m)' + 1)
local ++i
}

lrtest  MVL MVL_np, force
mat AIC[7, 1] = r(p)
lrtest  PDV PDV_np, force
mat AIC[8, 1] = r(p)
lrtest TI TI_np, force
mat AIC[9, 1] = r(p)
mat list AIC
mat AIC1 = (AIC[1..3, 1] , AIC[4..6, 1], AIC[7..9, 1])
mat list AIC1

***********************************************************************************************************
**************************************** Table 2 incidence ************************************************
***********************************************************************************************************
foreach var of varlist HIV_pcat Female AgeGrp1 urban Marital PartnerCat AIQ {
  stptime , by(`var') per(100) dd(2) output(`var', replace)
}



mat define Out = J(1, 4, .)
foreach var of varlist MVL PDV TI P_MVL P_PDV P_TI {
  dis as text _n "=========== `var'"
  cap drop `var'_q
  egen `var'_q = xtile(`var'), n(4)
  forvalue i = 1/4 {
  stptime if `var'_q==`i', per(100) dd(2) 
    mat define `var'`i' = J(1, 4, .)
    mat rownames `var'`i' = "`var'`i'"
    mat `var'`i'[1, 1] = `i'
    mat `var'`i'[1,2] = r(rate) 
    mat `var'`i'[1, 3] = r(lb)
    mat `var'`i'[1, 4] = r(ub)
    mat list `var'`i'
    mat Out = Out \ `var'`i'
  }
}
mat Out =  Out[2..., 1...]
mat colnames Out = Q Rate lb ub
mat2txt , matrix(Out) saving("$output/coefMat.txt") replace 


***********************************************************************************************************
**************************************** For plot of coeff ************************************************
***********************************************************************************************************



mat coef = MVL \ PDV\ TI\ P_MVL\ P_PDV\ P_TI
mat list coef
putexcel set "$output/coefMatrix", replace
putexcel A1=matrix(coef, names)
