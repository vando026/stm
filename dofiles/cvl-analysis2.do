//  program:    analysis2.do
//  task:	This is the analysis file for CVL cox model
//  project:	CVL
//  author:     AV / Created: 03Feb2016 

***********************************************************************************************************
**************************************** Single Rec Data **************************************************
***********************************************************************************************************
** log using "$output/FrankCompare.txt", text replace
log using "$output/Output.txt", replace text 

use "$derived/cvl-analysis2", clear
keep if !missing(PVL_geo_me, ART_geo_me, PPDV_PVL, PPDV_FVL, PVL_Quinn_Transmission_rate, FVL_Quinn_Transmission_rate)

stset  EndDate, failure(SeroConvertEvent==1) entry(EarliestHIVNegative) ///
  origin(EarliestHIVNegative) scale(365.25) exit(EndDate)

distinct IIntID 

** Set covariates here once, so you dont have to do it x times for x models
global prev "i.HIV_pcat"
global vars "i.AgeGrp1 ib1.urban ib1.Marital ib0.PartnerCat ib1.AIQ"
global sex_vars "Female $vars"

***********************************************************************************************************
**************************************** Model 1 **********************************************************
***********************************************************************************************************

foreach var of varlist *_unadjusted  {
  dis as text _n "=========================================> Showing for `var'"
  stcox `var', noshow
  stcox `var' $prev, noshow
  stcox `var' $prev $vars, noshow
} 

foreach var of varlist PPDV_?VL {
  dis as text _n "=========================================> Showing for `var'"
  stcox `var', noshow
  stcox `var' $sex_vars, noshow
} 

foreach var of varlist *Quinn_Index *Quinn_Trans* {
  dis as text _n "=========================================> Showing for `var'"
  stcox `var', noshow
  stcox `var' $sex_vars, noshow
} 

** foreach var of varlist *Quinn_Index_cat {
**   dis as text _n "=========================================> Showing for `var'"
**   stcox i.`var', noshow
**   stcox i.`var' $sex_vars, noshow
** } 

log close

preserve
keep if Female==1
foreach var of varlist PPDV_?VL_Males *VL_Males {
  stcox `var'
  stcox `var' $vars
}
restore

preserve
keep if Female==0
foreach var of varlist PPDV_?VL_Females *VL_Females {
  stcox `var'
  stcox `var' $vars
}
restore



***********************************************************************************************************
***************************************** Model 1 *********************************************************
***********************************************************************************************************
** population viral load--geometric mean, for a 1000 copies/ml increase
** eststo pgm1: stcox PVL_geo_me, noshow
** eststo pgm2: stcox PVL_geo_me i.HIV_pcat, noshow
eststo pgm3: stcox PVL_geo_me $prev $sex_vars, noshow

***********************************************************************************************************
**************************************** Model 2***********************************************************
***********************************************************************************************************
** population prevalence of detectable viremia for a 1 percent increase
** eststo ppvl1: stcox ppvl_pc , noshow
** eststo ppvl2: stcox ppvl_pc i.HIV_pcat , noshow
eststo ppvl3: stcox PPDV_PVL $sex_vars, noshow

***********************************************************************************************************
**************************************** Model 3***********************************************************
***********************************************************************************************************
** facility-based prevalence of detectable viremia 
** eststo apvl1: stcox apvl_pc , noshow
** eststo apvl2: stcox apvl_pc $prev , noshow
eststo apvl3: stcox PPDV_FVL $sex_vars, noshow

***********************************************************************************************************
**************************************** Model 4***********************************************************
***********************************************************************************************************
** facility-based geometric mean
** eststo agm1: stcox FVL_unadjusted , noshow
** eststo agm2: stcox FVL_unadjusted $prev , noshow
eststo agm3: stcox ART_geo_me $prev $sex_vars, noshow

***********************************************************************************************************
**************************************** Combined *********************************************************
***********************************************************************************************************
global opts1 "cells("b(fmt(%9.3f)) ci(par(( - ))) p") substitute(0.000 "<0.001") rtf compress"
global opts2 "eform varwidth(12) modelwidth(6 13 6) nonumbers nogaps replace"
global opts3 "mlabels(PVL PPDV FVL FPDV)"
global names "rename(pgm1000 cvl ppvl_pc cvl agm1000 cvl apvl_pc cvl)"

esttab pgm3 ppvl3 agm3 apvl3 using "$output/Model2.rtf", $opts1 $opts2 $opts3 $names

***********************************************************************************************************
****************************************  Quinn ***********************************************************
***********************************************************************************************************
** eststo pvlq: stcox PVL_Quinn_Index $sex_vars, noshow
eststo pvlqt: stcox PVL_Quinn_Transmission_rate $sex_vars, noshow
** eststo fvlq: stcox FVL_Quinn_Index $sex_vars, noshow
eststo fvlqt: stcox FVL_Quinn_Transmission_rate $sex_vars, noshow
global opts3 "mlabels(PQ PQT FQ FQT)"

esttab pvlqt fvlqt using "$output/Model3.rtf", $opts1 $opts2 $opts3 $names


***********************************************************************************************************
**************************************** Compare model fit ************************************************
***********************************************************************************************************
** Get the model with no HIV prevalence
est restore ppvl3
est restore pgm3
** Run a likelhood test
lrtest  , force

** Compute AIC = -2ln L + 2(k+c), k is model parameters
est restore ppvl3
global ppvl3_ll =  e(ll)
dis -2*$ppvl3_ll + 2*(4 + 1)
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


