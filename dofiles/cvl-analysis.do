//  program:    analysis.do
//  task:	
//  project:	Name
//  author:     AV / Created: 19Jan2016

** The plan is to produce graphs for CVL and FVL by year 2011 and gender

***********************************************************************************************************
**************************************** Analyze **********************************************************
***********************************************************************************************************
use "$derived/FVL2011", clear 
gen Over50k = cond(ViralLoad>=50000, 1, 0)

global methods "mean median gmean"
foreach m of global methods {
  plotVL ViralLoad, data(FVL) year(2011) method(`m')
}
** plotVL Over50k, data(FVL) year(2011) prop 

use "$derived/CVL2011", clear 
gen Over50k = cond(ViralLoad>=50000, 1, 0)
foreach m of global methods {
  plotVL ViralLoad, data(CVL) year(2011) method(`m') comp
}

** plotVL Over50k, data(CVL) year(2011) comp prop


use "$derived/FVL2011", clear 
gen logVL=log(ViralLoad)
bysort Age: egen logVLmean=mean(logVL)
gen gmeanVL=exp(logVLmean)
bysort Age: egen meanVL = mean(ViralLoad)
bysort Age: ci meanVL

gen baseline=1
regress logVL baseline,noconst eform(GM/Ratio) robust
regress logVL baseline if Age==1,noconst eform(GM/Ratio) robust




/*
statsby mean50k=r(mean) sd50k=r(sd), ///
    by(TestYear Sex Age) saving("$derived/Over50k", replace): sum Over50k, d

statsby mean=r(mean) sd=r(sd) median=r(p50) q1=r(p25) q3=r(p75), ///
    by(TestYear Sex Age) clear: sum ViralLoad, d

merge 1:1 TestYear Sex Age using "$derived/Over50k", nogen
list *, clean
rename ViralLoad VLClinic

