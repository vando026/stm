//  program:    analysis.do
//  task:	
//  project:	Name
//  author:     AV / Created: 19Jan2016

***********************************************************************************************************
**************************************** Generate the Estimates *******************************************
***********************************************************************************************************
** Get summary stats for tables
use "$derived/CVLdat", clear 
egen AgeGrp1 = cut(Age), at(15(5)45, 100) label icode
gen Over50k = (ViralLoad>50000)

tab Female
tab AgeGrp1

ameans ViralLoad
** Comute geometric mean
statsby mean=r(mean_g) lb=r(lb_g) ub=r(ub_g), by(AgeGrp1) saving("$derived/gmean2011Age", replace): /// 
  ameans ViralLoad
preserve
use "$derived/gmean2011Age" , clear
foreach var of varlist * {
  replace `var' = round(`var',1)
}
list *, clean
restore

** Comute geometric mean
statsby mean=r(mean_g) lb=r(lb_g) ub=r(ub_g), by(Female) saving("$derived/gmean2011Fem", replace): /// 
  ameans ViralLoad
preserve
use "$derived/gmean2011Fem" , clear
foreach var of varlist * {
  replace `var' = round(`var',1)
}
list *, clean
restore


ameans Over50k
statsby mean=r(mean) lb=r(lb) ub=r(ub), by(AgeGrp1) saving("$derived/prop50_2011Age", replace): /// 
  ameans Over50k 
preserve
use "$derived/prop50_2011Age" , clear
foreach var of varlist mean lb ub {
  replace `var' = round(`var',0.01)
}
list *, clean
restore

statsby mean=r(mean) lb=r(lb) ub=r(ub), by(Female) saving("$derived/prop50_2011Fem", replace): /// 
  ameans Over50k 
preserve
use "$derived/prop50_2011Fem" , clear
foreach var of varlist mean lb ub {
  replace `var' = round(`var',0.01)
}
list *, clean
restore



foreach dat in gmean2011 mean2011 med2011 over50_2011 {
  use "$derived/`dat'", clear
  replace lb = 0 if lb < 0
  saveold "$derived/`dat'", replace
}

***********************************************************************************************
**************************************** FVL data *********************************************
***********************************************************************************************
use "$derived/FVLdat", clear 
recode AgeGrp (7=6)

gen Over50k = (ViralLoad>50000)

tab Female
tab AgeGrp

ameans ViralLoad
** Comute geometric mean
statsby mean=r(mean_g) lb=r(lb_g) ub=r(ub_g), by(AgeGrp) saving("$derived/fvl_gmean2011Age", replace): /// 
  ameans ViralLoad
preserve
use "$derived/fvl_gmean2011Age" , clear
foreach var of varlist * {
  replace `var' = round(`var',1)
}
list *, clean
restore

** Comute geometric mean
statsby mean=r(mean_g) lb=r(lb_g) ub=r(ub_g), by(Female) saving("$derived/fvl_gmean2011Fem", replace): /// 
  ameans ViralLoad
preserve
use "$derived/fvl_gmean2011Fem" , clear
foreach var of varlist * {
  replace `var' = round(`var',1)
}
list *, clean
restore


ameans Over50k

statsby mean=r(mean) lb=r(lb) ub=r(ub), by(AgeGrp) saving("$derived/fvl_prop50_2011Age", replace): /// 
  ameans Over50k 
preserve
use "$derived/fvl_prop50_2011Age" , clear
foreach var of varlist mean lb ub {
  replace `var' = round(`var',0.001)
}
list *, clean
restore

statsby mean=r(mean) lb=r(lb) ub=r(ub), by(Female) saving("$derived/fvl_prop50_2011Fem", replace): /// 
  ameans Over50k
preserve
use "$derived/fvl_prop50_2011Fem" , clear
foreach var of varlist mean lb ub {
  replace `var' = round(`var',0.001)
}
list *, clean
restore



