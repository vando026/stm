//  program:    analysis.do
//  task:	
//  project:	Name
//  author:     AV / Created: 19Jan2016

***********************************************************************************************************
**************************************** Generate the Estimates *******************************************
***********************************************************************************************************
** Get summary stats for tables
use "$derived/PVL2011", clear 
rename AgeTestedVL Age
bysort Data:  tab1 Female Age
bysort Data: sum ViralLoad, d
bysort Data: ameans ViralLoad
bysort Data: sum VLSuppressed
gen logVL = log10(ViralLoad)
** bysort Data: tab OnART 

gen Over50k = (ViralLoad>50000)

** Look at indiv only on ART
** drop if OnART == 1 

** Comute geometric mean
statsby mean=r(mean_g) lb=r(lb_g) ub=r(ub_g), by(Data Female Age) saving("$derived/gmean2011", replace): /// 
  ameans ViralLoad

statsby mean=r(mean) lb=r(lb) ub=r(ub), by(Data Female Age) saving("$derived/mean2011", replace): /// 
  ci logVL
  
statsby mean=r(p50) lb=r(p25) ub=r(p75), by(Data Female Age) saving("$derived/med2011", replace): /// 
  sum ViralLoad , detail

statsby mean=r(mean) lb=r(lb) ub=r(ub), by(Data Female Age) saving("$derived/over50_2011", replace): /// 
  ci Over50k 

foreach dat in gmean2011 mean2011 med2011 over50_2011 {
  use "$derived/`dat'", clear
  replace lb = 0 if lb < 0
  saveold "$derived/`dat'", replace
}

