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


* Multivariable abalysis: final model
*

xi:streg  geo_mean_lnvlresultcopiesml__1 hiv8_2011_prev_trim_1 i.AgeSex i.IsUrbanOrRural , d(weibull)
xi:streg  geo_mean_lnvlresultcopiesml__1  i.AgeSex i.IsUrbanOrRural , d(weibull)


xi:streg  prev_vlbaboveldlyesnoincneg__1 i.AgeSex i.IsUrbanOrRural , d(weibull)
