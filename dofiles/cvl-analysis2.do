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
  origin(EarliestHIVNegative) scale(365.25) 

** Set covariates here once, so you dont have to do it x times for x models
global prev "i.HIV_pcat"
global vars "Female i.AgeGrp1 ib1.urban ib1.Marital ib0.PartnerCat ib1.AIQ"

** For model output
global opts1 "cells("b(fmt(%9.3f)) ci(par(( - ))) p") substitute(0.000 "<0.001") compress"
global opts2 "eform varwidth(12) modelwidth(6 13 6) nonumbers nogaps replace aic(0)"
global opts3 "mlabels("Model 0" "Model 1" "Model 2" "Model 3")"
global opts6 "drop(0.HIV_pcat 0.AgeGrp1 1.urban 1.Marital 0.PartnerCat 1.AIQ)"
local opts5 "csv"


/***********************************************************************************************************
**************************************** No Negatives *****************************************************
***********************************************************************************************************
foreach var of varlist G_MVL PDV TI {
  dis as text _n "=========================================> Showing for `var'"
  ** stcox `var', noshow
  ** stcox `var' $vars, noshow
  ** stcox `var' $urban $vars, noshow
  ** stcox `var' $vars, noshow
  ** stcox `var' $prev $vars, noshow
} 
*/

global vars "Female ib1.urban i.AgeGrp1 ib1.Marital ib0.PartnerCat ib1.AIQ"
** foreach var of varlist G_PVL P_PDV P_CTI {
foreach var of varlist G_MVL PDV TI {
  dis as text _n "=========================================> Showing for `var' and Males"
  cap drop sch* sca* 
  qui stcox `var' $vars, noshow schoenfeld(sch*) scaledsch(sca*)
  stphtest, detail
} 
** stcox $prev
** log close
** As for the PH assumption, one can run a test to determine the particular variable that "violates" the PH assumption. In this case it is the Sex and Age variables. 
***********************************************************************************************************
***************************************** Table 3 unadjusted **********************************************
***********************************************************************************************************
global opts11 "cells("b(fmt(%9.3f)) ci(par(( - ))) p") substitute(0.000 "<0.001")"
global opts12 "nomti nogaps noobs eform nonumbers compress nonumbers nonotes mlabels(none) collabels(none)"
eststo mm: stcox $prev, noshow
esttab mm using "$output/Model1_Unad.`opts5'", $opts11 $opts12 replace

global opts4 order($vars)
foreach var of global vars   {
  eststo mm: stcox `var' , noshow
  esttab mm using "$output/Model1_Unad.`opts5'", $opts11 $opts12 append
}

stcox $vars
dis  -2*`=e(ll)' + 2*(`=e(df_m)' + 1)


***********************************************************************************************************
***************************************** CVL vars ******************************************************
***********************************************************************************************************
global CVL G_MVL PDV TI 
** Set 1
eststo mm: stcox G_MVL, noshow
esttab mm using "$output/Model_CVL_Unad.`opts5'", $opts11 $opts12 replace
foreach var in PDV TI   {
  eststo mm: stcox `var' , noshow
  esttab mm using "$output/Model_CVL_Unad.`opts5'", $opts11 $opts12 append
}

** Set 2
global vars "Female i.AgeGrp1 ib1.urban ib1.Marital ib0.PartnerCat ib1.AIQ"
foreach mod of global CVL {
  eststo `mod': stcox `mod' $vars , noshow
}
global opts3 "mlabels("Model 1" "Model 2" "Model 3")"
global opts4 order($CVL)
esttab $CVL using "$output/Model_CVL_Cov.`opts5'", $opts1 $opts2 $opts3 $opts4 `opts5' 

** Set 3
foreach mod of global CVL {
  eststo `mod': stcox `mod' $prev $vars , noshow
  mat `mod' = r(table)
  mat `mod' = `mod'[1..6,1]'
}
global opts4 order($CVL)
esttab $CVL using "$output/Model_CVL_All.`opts5'", $opts1 $opts2 $opts3 $opts4 `opts5' 

***********************************************************************************************************
***************************************** P_PVL vars ******************************************************
***********************************************************************************************************
** Set 1
eststo mm: stcox G_PVL, noshow
esttab mm using "$output/Model_PVL_Unad.`opts5'", $opts11 $opts12 replace
foreach var in P_PDV P_CTI   {
  eststo mm: stcox `var' , noshow
  esttab mm using "$output/Model_PVL_Unad.`opts5'", $opts11 $opts12 append
}

** Set 2
global PCVL G_PVL P_PDV P_CTI 
global opts4 order($PCVL)
global vars "Female i.AgeGrp1 ib1.urban ib1.Marital ib0.PartnerCat ib1.AIQ"
foreach mod of global PCVL {
  eststo `mod': stcox `mod' $vars , noshow
}
global opts3 "mlabels("Model 1" "Model 2" "Model 3")"
global opts4 order($PCVL)
esttab $PCVL using "$output/Model_PVL_Cov.`opts5'", $opts1 $opts2 $opts3 $opts4 `opts5' 

** Set 3
foreach mod of global PCVL {
  eststo `mod': stcox `mod' $prev $vars , noshow
  mat `mod' = r(table)
  mat `mod' = `mod'[1..6,1]'
}
global opts4 order($PCVL)
esttab $PCVL using "$output/Model_PVL_All.`opts5'", $opts1 $opts2 $opts3 $opts4 `opts5' 


***********************************************************************************************************
***************************************** P_FVL vars ******************************************************
***********************************************************************************************************
** Set 1
eststo mm: stcox G_FVL, noshow
esttab mm using "$output/Model_FVL_Unad.`opts5'", $opts11 $opts12 replace
foreach var in FVL_PDV FVL_TI   {
  eststo mm: stcox `var' , noshow
  esttab mm using "$output/Model_FVL_Unad.`opts5'", $opts11 $opts12 append
}

** Set 2
global FVL G_FVL FVL_PDV FVL_TI 
global opts4 order($FVL)
global vars "Female i.AgeGrp1 ib1.urban ib1.Marital ib0.PartnerCat ib1.AIQ"
foreach mod of global FVL {
  eststo `mod': stcox `mod' $vars , noshow
}
global opts3 "mlabels("Model 1" "Model 2" "Model 3")"
global opts4 order($FVL)
esttab $FVL using "$output/Model_FVL_Cov.`opts5'", $opts1 $opts2 $opts3 $opts4 `opts5' 

** Set 3
foreach mod of global FVL {
  eststo `mod': stcox `mod' $prev $vars , noshow
  mat `mod' = r(table)
  mat `mod' = `mod'[1..6,1]'
}
global opts4 order($FVL)
esttab $FVL using "$output/Model_FVL_All.`opts5'", $opts1 $opts2 $opts3 $opts4 `opts5' 



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
lrtest P_CTI_only P_CTI_prev, force
mat AIC[4, 4] = r(p)
mat list AIC


***********************************************************************************************************
**************************************** Correlaions ******************************************************
***********************************************************************************************************
pwcorr G_PVL G_FVL, sig
pwcorr P_PDV FVL_PDV, sig
pwcorr P_CTI FVL_TI, sig

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




***********************************************************************************************
**************************************** Refusal **********************************************
***********************************************************************************************
use "$AC_Data/HIVSurveillance/2015/RD05-001_ACDIS_HIV", clear
keep IIntID VisitDate HIVRefused HIVResult AgeAtVisit Sex 
gen Year = year(VisitDate)
keep if Year==2011
keep if AgeAtVisit >= 15
drop if AgeAtVisit > 55 & Sex==1 
drop if AgeAtVisit > 50 & Sex==2 
bysort Sex: sum AgeAtVisit
gen HIVRefusedRC = (HIVRefused==1)
tab1 HIVRefused*
