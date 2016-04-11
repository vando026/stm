//  program:    analysis.do
//  task:	
//  project:	Name
//  author:     AV / Created: 19Jan2016

***********************************************************************************************************
**************************************** Generate the Estimates *******************************************
***********************************************************************************************************
** Get summary stats for tables
use "$derived/PVL2011", clear 
bysort Data:  tab1 Female Age
bysort Data: sum ViralLoad, d
bysort Data: ameans ViralLoad
bysort Data: gen VLSuppr = (ViralLoad<1550) 
bysort Data: tab VLSuppr 

** Comute geometric mean
statsby mean=r(mean_g) lb=r(lb_g) ub=r(ub_g), by(Data Female Age) saving("$derived/gmean2011", replace): /// 
  ameans ViralLoad

statsby mean=r(mean) lb=r(lb) ub=r(ub), by(Data Female Age) saving("$derived/mean2011", replace): /// 
  ci ViralLoad
  
statsby mean=r(p50) lb=r(p25) ub=r(p75), by(Data Female Age) saving("$derived/med2011", replace): /// 
  sum ViralLoad , detail

statsby mean=r(mean) lb=r(lb) ub=r(ub), by(Data Female Age) saving("$derived/over50_2011", replace): /// 
  ci Over50k 

** PLot in R
