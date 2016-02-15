//  program:    analysis2.do
//  task:	This is the analysis file for CVL cox model
//  project:	CVL
//  author:     AV / Created: 03Feb2016 

***********************************************************************************************************
**************************************** Analysis *********************************************************
***********************************************************************************************************
use "$derived/cvl-analysis2", clear
stset  ObservationEnd, failure(SeroConvertEvent==1) origin(ObservationStart) id(IIntID) scale(365.25)

stptime, by(ExpYear) per (100)

***********************************************************************************************************
**************************************** Single Rec Data **************************************************
***********************************************************************************************************
log using "$output/analysis.txt", text replace
use "$derived/cvl-analysis2", clear
stset  EndDate, failure(SeroConvertEvent==1) origin(EarliestHIVNegative) scale(365.25) exit(EndDate)

/** legend:
pgm = pvl_geo_mean_lnvlresultcopiesml
ppvl = pvl_prev_vlbaboveldlyesnoincneg
ppvlg = pvl_prev_vlbaboveyesno_gauss199 */


gen logpgm = log(pgm)
stcox  logpgm HIV_prev i.urbpgm i.AgeSexCat
stcox  ppvl i.urbppvl i.AgeSexCat
stcox  ppvlg HIV_prev i.urbppvlg i.AgeSexCat
log close

gen logagm = log(agm)
stcox  logagm HIV_prev i.urbagm i.AgeSexCat
stcox  apvl i.urbapvl i.AgeSexCat
