//  program:    analysis.do
//  task:	
//  project:	Name
//  author:     AV / Created: 19Jan2016

***********************************************************************************************************
**************************************** Generate the Estimates *******************************************
***********************************************************************************************************
** Get summary stats for tables
use "$derived/CVLdat", clear 

tab1 Female AgeGrp
sum ViralLoad, d
ameans ViralLoad
sum DetectVL
gen logVL = log10(ViralLoad)
gen Over50k = (ViralLoad>50000)
gen SuppressVL = (DetectVL==0)

bysort Female: ameans SuppressVL 

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

***********************************************************************************************
**************************************** FVL data *********************************************
***********************************************************************************************
use "$derived/FVLdat", clear 
tab1 Female AgeGrp
sum ViralLoad, d
ameans ViralLoad
sum DetectVL
gen logVL = log10(ViralLoad)
gen Over50k = (ViralLoad>50000)

gen Over50k = (ViralLoad>50000)
