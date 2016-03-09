//  program:    analysis2.do
//  task:	This is the analysis file for CVL cox model
//  project:	CVL
//  author:     AV / Created: 03Feb2016 

** log using "$output/analysis.txt", text replace

/** legend:
pgm = pvl_geo_mean_lnvlresultcopiesml
ppvl = pvl_prev_vlbaboveldlyesnoincneg
ppvlg = pvl_prev_vlbaboveyesno_gauss199 */

***********************************************************************************************************
**************************************** Single Rec Data **************************************************
***********************************************************************************************************
** log using "$output/FrankExample.txt", text replace

use "$derived/cvl-analysis2", clear
stset  EndDate, failure(SeroConvertEvent==1) entry(EarliestHIVNegative) origin(EarliestHIVNegative) scale(365.25) exit(EndDate)


** pgm1000 = pvl_geo_mean_lnvlresultcopiesml/1000
** So the model shows that a 1000 vl copies/ml increase reduces hazard of HIV acquisition by 
** a factor of 0.14. 
stcox  pgm1000 
stcox  pgm1000 ARTCov2011

** Next I make HIV prevalence a categorial variable
tab HIV_pcat
** And also make pgm a categorial var
tab pgm1000_cat

** Then show results for prev on acquisition, which is reasonable
stcox  i.HIV_pcat
stcox  i.HIV_pcat ARTCov2011 

** Create an interaction between the two
stcox  c.pgm1000_cat##i.HIV_pcat ARTCov2011 
stcox  c.pgm1000_cat##i.HIV_pcat ARTCov2011 Sex Age i.urban
stcox  c.pgm1000_cat##i.HIV_pcat ARTCov2011 ib2.AgeSexCat i.urban

** stcox  c.pgm1000##i.HIV_pcat 
** stcox  c.pgm_cat##i.HIV_pcat 

log close

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
