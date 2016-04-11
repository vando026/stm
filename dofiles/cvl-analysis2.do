//  program:    analysis2.do
//  task:	This is the analysis file for CVL cox model
//  project:	CVL
//  author:     AV / Created: 03Feb2016 

/** legend:
pgm = pvl_geo_mean_lnvlresultcopiesml
ppvl = pvl_prev_vlbaboveldlyesnoincneg
ppvlg = pvl_prev_vlbaboveyesno_gauss199 */


***********************************************************************************************************
**************************************** Single Rec Data **************************************************
***********************************************************************************************************
** log using "$output/FrankCompare.txt", text replace
use "$derived/cvl-analysis2", clear
stset  EndDate, failure(SeroConvertEvent==1) entry(EarliestHIVNegative) ///
  origin(EarliestHIVNegative) scale(365.25) exit(EndDate)

***********************************************************************************************************
**************************************** Model 1 **********************************************************
***********************************************************************************************************
** population viral load--geometric mean, for a 1000 copies/ml increase
eststo pgm1: stcox pgm1000 , noshow
eststo pgm2: stcox pgm1000 i.HIV_pcat , noshow
eststo pgm3: stcox pgm1000 i.HIV_pcat Female i.AgeGrp1 , noshow

***********************************************************************************************************
**************************************** Model 2***********************************************************
***********************************************************************************************************
** population prevalence of detectable viremia for a 1 percent increase
eststo ppvl1: stcox ppvl_pc , noshow
eststo ppvl2: stcox ppvl_pc i.HIV_pcat , noshow
eststo ppvl3: stcox ppvl_pc i.HIV_pcat Female i.AgeGrp1 , noshow

***********************************************************************************************************
**************************************** Model 3***********************************************************
***********************************************************************************************************
** facility-based prevalence of detectable viremia 
eststo apvl1: stcox apvl_pc , noshow
eststo apvl2: stcox apvl_pc i.HIV_pcat , noshow
eststo apvl3: stcox apvl_pc i.HIV_pcat Female i.AgeGrp1 , noshow

***********************************************************************************************************
**************************************** Model 4***********************************************************
***********************************************************************************************************
** facility-based geometric mean
eststo agm1: stcox agm1000 , noshow
eststo agm2: stcox agm1000 i.HIV_pcat , noshow
eststo agm3: stcox agm1000 i.HIV_pcat Female i.AgeGrp1 , noshow

***********************************************************************************************************
**************************************** Combined *********************************************************
***********************************************************************************************************
global labels "coeflabel(0b.HIV_pcat "HIV prev. (0-14%)" 1.HIV_pcat "HIV prev. (15-24%)" 2.HIV_pcat "HIV prev. (25+%)" 0b.AgeGrp1 "Age 12-19" 1.AgeGrp1 "20-24" 2.AgeGrp1 "25-29" 3.AgeGrp1 "30-34" 4.AgeGrp1 "35-39" 5.AgeGrp1 "40-44" 6.AgeGrp1 "45+")"
global opts "cells(b ci p) rtf compress eform nomtitles varwidth(20) nogaps"

esttab pgm3 ppvl3 agm3 apvl3 using "$output/Model2.rtf", append $opts //$labels $title


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
