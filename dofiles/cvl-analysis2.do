//  program:    analysis2.do
//  task:	This is the analysis file for CVL cox model
//  project:	CVL
//  author:     AV / Created: 03Feb2016 



****************************************************************************
***************Perform Analysis*********************************************
****************************************************************************
*****Residents Only
** gen ExpYear1=ExpYear
** replace ExpYear1=2004 if ExpYear<2004
drop if pvl_quinn_index_gauss199_trim==0



stset  NewObservationEnd if (BSIntID !=. &  ExpYear>2010), failure(BSEpisodeSeroConvert) origin(NewObservationStart) id(IIntID) scale(365.25)


stptime, per (100)


* Multivariable abalysis: final model
*

xi:streg  geo_mean_lnvlresultcopiesml__1 hiv8_2011_prev_trim_1 i.AgeSex i.IsUrbanOrRural , d(weibull)
xi:streg  geo_mean_lnvlresultcopiesml__1  i.AgeSex i.IsUrbanOrRural , d(weibull)


xi:streg  prev_vlbaboveldlyesnoincneg__1 i.AgeSex i.IsUrbanOrRural , d(weibull)
