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
foreach var of varlist Log_MVL PDV TI {
  dis as text _n "=========================================> Showing for `var'"
  stcox `var', noshow
  stcox `var' $urban $vars, noshow
  stcox `var'  $prev $urban $vars, noshow
} 

foreach var of varlist P_MVL P_PDV P_TI G_PVL {
  dis as text _n "=========================================> Showing for `var'"
  ** stcox `var', noshow
  ** stcox `var' $vars, noshow
  stcox `var' $urban $vars, noshow
  ** stcox `var' $prev $urban $vars, noshow
} 

log close

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
**************************************** Table 2 incidence ************************************************
***********************************************************************************************************
foreach var of varlist HIV_pcat Female AgeGrp1 urban Marital PartnerCat AIQ {
  stptime , by(`var') per(100) dd(2) 
}

stptime, by(Female) per(100)
strate  Female , per(100) output("$output/test", replace) 


mat define Out = J(1, 5, .)
foreach var of varlist MVL PDV TI P_MVL P_PDV P_TI {
  dis as text _n "=========== `var'"
  cap drop `var'_q
  egen `var'_q = xtile(`var'), n(4)
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


***********************************************************************************************************
**************************************** For plot of coeff ************************************************
***********************************************************************************************************
mat coef = MVL \ PDV\ TI\ P_MVL\ P_PDV\ P_TI
mat2txt, matrix(coef) saving("$output/coefHR.txt") replace


mat define Out1 = J(1, 5, .)
foreach var of varlist TI_q P_TI_q {
stcox ib1.`var' Female
mat `var' = r(table)
mat `var' = `var'[1..6,2..4]'
mat list `var'
}
mat Out1 =  TI_q \ P_TI_q
mat2txt  , matrix(Out1) saving("$output/coefTI.txt") replace


pwcorr G_PVL G_FVL, sig
pwcorr P_PDV FVL_PDV, sig
pwcorr P_TI FVL_TI, sig
