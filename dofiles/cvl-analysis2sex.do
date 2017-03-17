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
global vars "i.AgeGrp1 ib1.urban ib1.Marital ib0.PartnerCat ib1.AIQ"

** For model output
global opts1 "cells("b(fmt(%9.3f)) ci(par(( - ))) p") substitute(0.000 "<0.001") compress"
global opts2 "eform varwidth(12) modelwidth(6 13 6) nonumbers nogaps replace aic(0)"
global opts3 "mlabels("Model 0" "Model 1" "Model 2" "Model 3")"
local opts5 "csv"

capture drop HIV_pcat_Female
egen HIV_pcat_Female = cut(HIV_Prev_Female), at(0, 20, 25, 35, 40) icode label

capture drop HIV_pcat_Male
egen HIV_pcat_Male = cut(HIV_Prev_Male), at(0, 5, 10, 15, 25) icode label

***********************************************************************************************
**************************************** Unad Males *******************************************
***********************************************************************************************
global opts11 "cells("b(fmt(%9.3f)) ci(par(( - ))) p") substitute(0.000 "<0.001")"
global opts12 "nomti nogaps noobs eform nonumbers compress nonumbers nonotes mlabels(none) collabels(none)"
** For men, what is the female prevalence
eststo mm: stcox i.HIV_pcat_Female, noshow
esttab mm using "$output/Model1_Unad_Mal.`opts5'", $opts11 $opts12 replace

global opts4 order($vars)
foreach var of global vars   {
  eststo mm: stcox `var' if Female==0 , noshow
  esttab mm using "$output/Model1_Unad_Mal.`opts5'", $opts11 $opts12 append
}

***********************************************************************************************************
***************************************** P_PVL vars males **********************************************
***********************************************************************************************************
** Set 1
eststo mm: stcox G_PVL_Female if Female==0, noshow
esttab mm using "$output/Model_PVL_Unad_Mal.`opts5'", $opts11 $opts12 replace
foreach var of varlist P_PDV_Female P_CTI_Female   {
  eststo mm: stcox `var' if Female==0 , noshow
  esttab mm using "$output/Model_PVL_Unad_Mal.`opts5'", $opts11 $opts12 append
}

** Set 2
global PCVLm G_PVL_Female P_PDV_Female P_CTI_Female 
global opts4 order($PCVLm)
foreach mod of global PCVLm {
  eststo `mod': stcox `mod' $vars if Female==0, noshow
}
global opts3 "mlabels("Model 1" "Model 2" "Model 3")"
global opts4 order($PCVLm)
esttab $PCVLm using "$output/Model_PVL_Cov_Mal.`opts5'", $opts1 $opts2 $opts3 $opts4 `opts5' 

** Set 3
foreach mod of global PCVLm {
  eststo `mod': stcox `mod' i.HIV_pcat_Female $vars if Female==0, noshow
}
global opts4 order($PCVLm)
esttab $PCVLm using "$output/Model_PVL_All_Mal.`opts5'", $opts1 $opts2 $opts3 $opts4 `opts5' 

***********************************************************************************************
**************************************** Unad Females *******************************************
***********************************************************************************************
global opts11 "cells("b(fmt(%9.3f)) ci(par(( - ))) p") substitute(0.000 "<0.001")"
global opts12 "nomti nogaps noobs eform nonumbers compress nonumbers nonotes mlabels(none) collabels(none)"
eststo mm: stcox i.HIV_pcat_Male, noshow
esttab mm using "$output/Model1_Unad_Fem.`opts5'", $opts11 $opts12 replace
global opts4 order($vars)
foreach var of global vars   {
  eststo mm: stcox `var' if Female==0 , noshow
  esttab mm using "$output/Model1_Unad_Fem.`opts5'", $opts11 $opts12 append
}



***********************************************************************************************************
***************************************** P_PVL vars females **********************************************
***********************************************************************************************************
** Set 1
eststo mm: stcox G_PVL_Male if Female==1, noshow
esttab mm using "$output/Model_PVL_Unad_Fem.`opts5'", $opts11 $opts12 replace
foreach var of varlist P_PDV_Male P_CTI_Male   {
  eststo mm: stcox `var' if Female==1 , noshow
  esttab mm using "$output/Model_PVL_Unad_Fem.`opts5'", $opts11 $opts12 append
}

** Set 2
global PCVLf G_PVL_Male P_PDV_Male P_CTI_Male 
global opts4 order($PCVLf)
foreach mod of global PCVLf {
  eststo `mod': stcox `mod' $vars if Female==1, noshow
}
global opts3 "mlabels("Model 1" "Model 2" "Model 3")"
global opts4 order($PCVLf)
esttab $PCVLf using "$output/Model_PVL_Cov_Fem.`opts5'", $opts1 $opts2 $opts3 $opts4 `opts5' 

** Set 3
foreach mod of global PCVLf {
  eststo `mod': stcox `mod' i.HIV_pcat_Male $vars if Female==1, noshow
}
global opts4 order($PCVLf)
esttab $PCVLf using "$output/Model_PVL_All_Fem.`opts5'", $opts1 $opts2 $opts3 $opts4 `opts5' 

***********************************************************************************************
***********************************************************************************************
***********************************************************************************************
