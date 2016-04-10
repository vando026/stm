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

foreach var of varlist pgm1000 cmnLogVL *pvl*_pc  {
  stcox `var', noshow
  stcox `var' i.HIV_pcat, noshow
  stcox `var' i.HIV_pcat Female i.AgeGrp1, noshow
}


foreach var of varlist pgm*_cat *pvl*_pcat  {
  stcox i.`var', noshow
}



***********************************************************************************************************
**************************************** Model 1 **********************************************************
***********************************************************************************************************
eststo mod1: stcox pgm1000 , noshow
eststo mod2: stcox pgm1000 i.HIV_pcat , noshow
eststo mod3: stcox pgm1000 i.HIV_pcat Female i.AgeGrp1 , noshow


global title "title("Table 2: Cox PH results for community viral load (VL) geometric mean.")"
global opts "rtf compress eform nomtitles varwidth(20) nogaps"
global labels "coeflabel(pgm1000 "Community VL" 0b.HIV_pcat "HIV prev. (0-14%)" 1.HIV_pcat "HIV prev. (15-24%)" 2.HIV_pcat "HIV prev. (25+%)" 0b.AgeGrp1 "Age 12-19" 1.AgeGrp1 "20-24" 2.AgeGrp1 "25-29" 3.AgeGrp1 "30-34" 4.AgeGrp1 "35-39" 5.AgeGrp1 "40-44" 6.AgeGrp1 "45+")"
esttab mod1 mod2 mod3 using "$output/Model1.rtf", replace $opts $labels $title


***********************************************************************************************************
**************************************** Model 2***********************************************************
***********************************************************************************************************
eststo mod1: stcox ppvl_pc , noshow
eststo mod2: stcox ppvl_pc i.HIV_pcat , noshow
eststo mod3: stcox ppvl_pc i.HIV_pcat Female i.AgeGrp1 , noshow

global title "title("Table 3: Cox PH results for population prevalence of detectable viral load (PPDV).")"
global labels "coeflabel(ppvl_pc "PPDV" 0b.HIV_pcat "HIV prev. (0-14%)" 1.HIV_pcat "HIV prev. (15-24%)" 2.HIV_pcat "HIV prev. (25+%)" 0b.AgeGrp1 "Age 12-19" 1.AgeGrp1 "20-24" 2.AgeGrp1 "25-29" 3.AgeGrp1 "30-34" 4.AgeGrp1 "35-39" 5.AgeGrp1 "40-44" 6.AgeGrp1 "45+")"
esttab mod1 mod2 mod3 using "$output/Model1.rtf", append $opts $labels $title

***********************************************************************************************************
**************************************** Model 3***********************************************************
***********************************************************************************************************
eststo mod1: stcox apvl_pc , noshow
eststo mod2: stcox apvl_pc i.HIV_pcat , noshow
eststo mod3: stcox apvl_pc i.HIV_pcat Female i.AgeGrp1 , noshow


global title "title("Table 4: Cox PH results for facility-based prevalence of detectable viral load (PPDV).")"
global labels "coeflabel(apvl_pc "FPDV" 0b.HIV_pcat "HIV prev. (0-14%)" 1.HIV_pcat "HIV prev. (15-24%)" 2.HIV_pcat "HIV prev. (25+%)" 0b.AgeGrp1 "Age 12-19" 1.AgeGrp1 "20-24" 2.AgeGrp1 "25-29" 3.AgeGrp1 "30-34" 4.AgeGrp1 "35-39" 5.AgeGrp1 "40-44" 6.AgeGrp1 "45+")"
esttab mod1 mod2 mod3 using "$output/Model1.rtf", append $opts $labels $title


***********************************************************************************************************
**************************************** Model 4***********************************************************
***********************************************************************************************************
eststo mod1: stcox agm1000 , noshow
eststo mod2: stcox agm1000 i.HIV_pcat , noshow
eststo mod3: stcox agm1000 i.HIV_pcat Female i.AgeGrp1 , noshow


***********************************************************************************************************
**************************************** Combined *********************************************************
***********************************************************************************************************
global labels "coeflabel(0b.HIV_pcat "HIV prev. (0-14%)" 1.HIV_pcat "HIV prev. (15-24%)" 2.HIV_pcat "HIV prev. (25+%)" 0b.AgeGrp1 "Age 12-19" 1.AgeGrp1 "20-24" 2.AgeGrp1 "25-29" 3.AgeGrp1 "30-34" 4.AgeGrp1 "35-39" 5.AgeGrp1 "40-44" 6.AgeGrp1 "45+")"

eststo modA: stcox pgm1000 i.HIV_pcat Female i.AgeGrp1 , noshow
eststo modB: stcox ppvl_pc i.HIV_pcat Female i.AgeGrp1 , noshow
eststo modC: stcox agm1000 i.HIV_pcat Female i.AgeGrp1 , noshow
eststo modD: stcox apvl_pc i.HIV_pcat Female i.AgeGrp1 , noshow
esttab modA modB modC modD using "$output/Model2.rtf", append $opts $labels $title



tab Female
tab AgeGrp1 
tab urban

foreach var of varlist pgm ppvl_pc agm apvl_pc {
  summ `var', d
}




/*


** So the model shows that a 1000 vl copies/ml increase reduces hazard of HIV acquisition by 

** a factor of 0.14. 

bysort Female: stcox  cmnLogVL

** Next I make HIV prevalence a categorial variable
tab HIV_pcat

** Then show results for prev on acquisition, which is reasonable
bysort Female: stcox  i.HIV_pcat 

** Create an interaction between the two
bysort Female: stcox  c.cmnLogVL##i.HIV_pcat 
stcox  c.cmnLogVL##i.HIV_pcat Female
** log close


stcox ppvl
stcox ppvlg
stcox ppvl_pc 
stcox ppvlg_pc 

stcox cmnLogVL

stcox pgm1000
stcox pgm1000 HIV_prev
stcox pgm1000 i.HIV_pcat
stcox c.pgm1000##i.HIV_pcat Female i.AgeGrp1
stcox ppvl_pc i.HIV_pcat Female i.AgeGrp1
stcox c.ppvl_pc##i.HIV_pcat Female i.AgeGrp1
stcox ppvlg_pc i.HIV_pcat Female i.AgeGrp1
stcox c.cmnLogVL i.HIV_pcat Female i.AgeGrp1


stcox ppvl_pc
stcox i.HIV_pcat ppvl_pc
stcox HIV_prev ppvl_pc



stcox i.HIV_pcat apvl_pc
stcox i.HIV_pcat agm1000
stcox i.HIV_pcat pgm1000



stcox ppvlg_pc
stcox i.HIV_pcat ppvlg_pc



stcox i.HIV_pcat
stcox ppvlg_pc
stcox i.HIV_pcat ppvl_pc Female
stcox i.HIV_pcat ppvlg_pc
stcox i.HIV_pcat##c.ppvl_pc
stcox i.HIV_pcat##c.ppvlg_pc


streg i.HIV_pcat , dist(weibull) 
streg i.HIV_pcat ppvl_pc , dist(weibull)

stcox  c.mnLogVL##i.HIV_pcat ARTCov2011_10
stcox  c.mnLogVL##i.HIV_pcat Sex i.urban
stcox  c.mnLogVL##i.HIV_pcat ib2.AgeSexCat i.urban

log close



** stcox  c.pgm1000##i.HIV_pcat 
** stcox  c.pgm_cat##i.HIV_pcat 


stcox  logpgm HIVpc i.urban ib2.AgeSexCat

** what proportion of positives are supperessed 
stcox  i.ppvl_pcat
stcox  ppvl_pc i.urban i.AgeSexCat
stcox  ppvlg_pc i.urban i.AgeSexCat

** Do for FVL data
stcox  logagm HIV_prev i.urban ib2.AgeSexCat
stcox  apvl_pc i.urban i.AgeSexCat
stcox  apvlg_pc i.urban i.AgeSexCat

***********************************************************************************************************
**************************************** Interval Censoring ***********************************************
***********************************************************************************************************

  ** Gives estimates as log-hazard ratios
  stpm  logpgm , left(_t0) df(1) scale(hazard)
  stpm  logpgm HIV_prev, left(_t0) df(1) scale(hazard)
  stpm  logpgm HIV_prev U2 U3 AF2-AF14 ,  left(_t0) df(1) scale(hazard)
  stpm  logpgm HIV_prev U2 U3 AF2-AF14 ,  left(_t0) df(1) scale(odds)


  stpm  ppvl_pc U2 U3 AF2-AF14 ,  left(_t0) df(1) scale(hazard)
  stpm  apvl_pc U2 U3 AF2-AF14 ,  left(_t0) df(1) scale(hazard)
