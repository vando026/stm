//  program:    analysis2.do
//  task:	This is the analysis file for CVL cox model
//  project:	CVL
//  author:     AV / Created: 03Feb2016 

** log using "$output/analysis.txt", text replace

/** legend:
gm = pvl_geo_mean_lnvlresultcopiesml
ppvl = pvl_prev_vlbaboveldlyesnoincneg
ppvlg = pvl_prev_vlbaboveyesno_gauss199 */

***********************************************************************************************************
**************************************** Single Rec Data **************************************************
***********************************************************************************************************
use "$derived/cvl-analysis2", clear
stset  EndDate, failure(SeroConvertEvent==1) entry(EarliestHIVNegative) origin(EarliestHIVNegative) scale(365.25) exit(EndDate)

if "$enddate"=="impute" {

  ** Do for CVL data
  stcox  logpgm HIV_prev i.urban i.AgeSexCat
  stcox  ppvl_pc i.urban i.AgeSexCat
  stcox  ppvlg_pc i.urban i.AgeSexCat

  ** Do for FVL data
  stcox  logagm HIV_prev i.urban i.AgeSexCat
  stcox  apvl_pc i.urban i.AgeSexCat
  stcox  apvlg_pc i.urban i.AgeSexCat
}

***********************************************************************************************************
**************************************** Interval Censoring ***********************************************
***********************************************************************************************************
** Try interval censoring
if "$enddate"!="impute" {

  ** Gives estimates as log-hazard ratios
  stpm  logpgm HIV_prev, left(_t0) df(1) scale(hazard)
  stpm  logpgm HIV_prev U2 U3 AF2-AF14 ,  left(_t0) df(1) scale(hazard)
  stpm  logpgm HIV_prev U2 U3 AF2-AF14 ,  left(_t0) df(1) scale(odds)


  stpm  ppvl_pc U2 U3 AF2-AF14 ,  left(_t0) df(1) scale(hazard)
  stpm  apvl_pc U2 U3 AF2-AF14 ,  left(_t0) df(1) scale(hazard)
}
