//  program:    analysis2.do
//  task:	This is the analysis file for CVL cox model
//  project:	CVL
//  author:     AV / Created: 03Feb2016 

***********************************************************************************************************
**************************************** Single Rec Data **************************************************
***********************************************************************************************************
** log using "$output/FrankCompare.txt", text replace
use "$derived/cvl-analysis2", clear
stset  EndDate, failure(SeroConvertEvent==1) entry(EarliestHIVNegative) ///
  origin(EarliestHIVNegative) scale(365.25) exit(EndDate)

** Set covariates here once, so you dont have to do it x times for x models
global prev "i.HIV_pcat"
global vars "Female i.AgeGrp1 ib1.urban ib1.Marital ib0.PartnerCat ib1.AIQ"

***********************************************************************************************************
**************************************** Model 1 **********************************************************
***********************************************************************************************************
log using "$output/Output.txt", replace text 

foreach var of varlist *geo* {
  dis as text _n "=========================================> Showing for `var'"
  stcox `var', noshow
  stcox `var' $prev, noshow
  stcox `var' $prev $vars, noshow
} 


foreach var of varlist *prev_v {
  dis as text _n "=========================================> Showing for `var'"
  stcox `var', noshow
  stcox `var' $vars, noshow
} 


** foreach var of varlist PVL_unadjusted - PPDV_PVL_Males  {
foreach var of varlist *_unadjusted  {
  dis as text _n "=========================================> Showing for `var'"
  stcox `var', noshow
  stcox `var' $prev, noshow
  stcox `var' $prev $vars, noshow
} 


foreach var of varlist PPDV_?VL {
  dis as text _n "=========================================> Showing for `var'"
  stcox `var', noshow
  stcox `var' $vars, noshow
} 
log close 

***********************************************************************************************************
***************************************** Model 1 *********************************************************
***********************************************************************************************************
** population viral load--geometric mean, for a 1000 copies/ml increase
eststo pgm1: stcox PVL_unadjusted, noshow
eststo pgm2: stcox PVL_geo_me_1000 i.HIV_pcat, noshow
eststo pgm3: stcox PVL_geo_me_1000 i.HIV_pcat $vars, noshow

***********************************************************************************************************
**************************************** Model 2***********************************************************
***********************************************************************************************************
** population prevalence of detectable viremia for a 1 percent increase
eststo ppvl1: stcox ppvl_pc , noshow
eststo ppvl2: stcox ppvl_pc i.HIV_pcat , noshow
eststo ppvl3: stcox ppvl_pc $vars, noshow

***********************************************************************************************************
**************************************** Model 3***********************************************************
***********************************************************************************************************
** facility-based prevalence of detectable viremia 
eststo apvl1: stcox apvl_pc , noshow
eststo apvl2: stcox apvl_pc $prev , noshow
eststo apvl3: stcox apvl_pc $vars, noshow

***********************************************************************************************************
**************************************** Model 4***********************************************************
***********************************************************************************************************
** facility-based geometric mean
eststo agm1: stcox FVL_unadjusted , noshow
eststo agm2: stcox FVL_unadjusted $prev , noshow
eststo agm3: stcox FVL_unadjusted $vars, noshow

***********************************************************************************************************
**************************************** Combined *********************************************************
***********************************************************************************************************
global opts1 "cells("b(fmt(%9.3f)) ci(par(( - ))) p") substitute(0.000 "<0.001") rtf compress"
global opts2 "eform varwidth(12) modelwidth(6 13 6) nonumbers nogaps replace"
global opts3 "mlabels(PVL PPDV FVL FPDV)"
global names "rename(pgm1000 cvl ppvl_pc cvl agm1000 cvl apvl_pc cvl)"

esttab pgm3 ppvl3 agm3 apvl3 using "$output/Model2.rtf", $opts1 $opts2 $opts3 $names


***********************************************************************************************************
**************************************** Compare model fit ************************************************
***********************************************************************************************************
** Get the model with no HIV prevalence
est restore ppvl3
** Run a likelhood test
lrtest ppvl2, force

** Compute AIC = -2ln L + 2(k+c), k is model parameters
est restore ppvl2
global ppvl2_ll =  e(ll)
dis -2*$ppvl2_ll + 2*(4 + 1)
** Pseudo R-squared
dis "`e(r2_p)'"

est restore ppvl3
global ppvl3_ll =  e(ll)
dis -2*$ppvl3_ll + 2*(5 + 1)
** Psuedo R squared
dis "`e(r2_p)'"


***********************************************************************************************************
**************************************** Table 2 incidence ************************************************
***********************************************************************************************************
use "$derived/cvl-analysis2", clear 
stset  EndDate, failure(SeroConvertEvent==1) entry(EarliestHIVNegative) ///
  origin(EarliestHIVNegative) scale(365.25) exit(EndDate) id(IIntID)

foreach var of varlist HIV_pcat Female AgeGrp1 urban Marital PartnerCat AIQ {
  stptime , by(`var') per(100) dd(2)
}


